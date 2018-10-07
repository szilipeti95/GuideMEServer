//
//  ChatService.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 06..
//

import Dispatch
import Foundation
import KituraWebSocket
import SwiftKuery
import SwiftKueryMySQL

public class ChatService: WebSocketService {

  private let connectionsLock = DispatchSemaphore(value: 1)

  #if os(Linux)
  let sqlUser = "app"
  let sqlPassword = "ppa"
  let sqlHost = "localhost"
  #else
  let sqlUser = "internalAPI"
  let sqlPassword = "IPAlanretni"
  let sqlHost = "127.0.0.1"
  #endif
  let sqlPort = 4306
  let sqlDatabase = "guideme"
  let pool: ConnectionPool!

  //Name, ConnectedTo, OwnConnection
  private var connections = [String: (String, String, WebSocketConnection)]()

  public init() {
    pool = MySQLConnection.createPool(url: URL(string: "mysql://\(sqlUser):\(sqlPassword)@\(sqlHost):\(sqlPort)/\(sqlDatabase)")!,
                                      poolOptions: ConnectionPoolOptions(initialCapacity: 10,
                                                                         maxCapacity: 50,
                                                                         timeout: 10000))
  }

  private enum MessageType: Character {
    case clientInChat = "c"
    case connected = "C"
    case disconnected = "D"
    case sentMessage = "M"
    case stoppedTyping = "S"
    case startedTyping = "T"
  }

  /// Called when a WebSocket client connects to the server and is connected to a specific
  /// `WebSocketService`.
  ///
  /// - Parameter connection: The `WebSocketConnection` object that represents the client's
  ///                    connection to this `WebSocketService`
  public func connected(connection: WebSocketConnection) {
    /*
    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        guard selectResult.success, let selected = selectResult.asRows?.first else {
          print(selectResult.asError as Any)
          return
        }
        let userResponse = User(dict: selected)
        try? response.send(userResponse.toJson()).end()
      }
    } else {

    }
    connection.send(message: connection.id)
    print(connection.id)
    // Ignored
    */
  }

  /// Called when a WebSocket client disconnects from the server.
  ///
  /// - Parameter connection: The `WebSocketConnection` object that represents the connection that
  ///                    was disconnected from this `WebSocketService`.
  /// - Paramater reason: The `WebSocketCloseReasonCode` that describes why the client disconnected.
  public func disconnected(connection: WebSocketConnection, reason: WebSocketCloseReasonCode) {
    lockConnectionsLock()
    if let disconnectedConnectionData = connections.removeValue(forKey: connection.id) {
      for (_, (_,_, from)) in connections {
        from.send(message: "\(MessageType.disconnected.rawValue):" + disconnectedConnectionData.0)
      }
    }
    unlockConnectionsLock()
  }

  /// Called when a WebSocket client sent a binary message to the server to this `WebSocketService`.
  ///
  /// - Parameter message: A Data struct containing the bytes of the binary message sent by the client.
  /// - Parameter client: The `WebSocketConnection` object that represents the connection over which
  ///                    the client sent the message to this `WebSocketService`
  public func received(message: Data, from: WebSocketConnection) {
    invalidData(from: from, description: "Kitura-Chat-Server only accepts text messages")
  }

  /// Called when a WebSocket client sent a text message to the server to this `WebSocketService`.
  ///
  /// - Parameter message: A String containing the text message sent by the client.
  /// - Parameter client: The `WebSocketConnection` object that represents the connection over which
  ///                    the client sent the message to this `WebSocketService`
  public func received(message: String, from: WebSocketConnection) {
    guard message.count > 1 else { return }

    guard let messageType = message.first else { return }

    let displayName = String(message.dropFirst(2))

    if messageType == MessageType.sentMessage.rawValue || messageType == MessageType.startedTyping.rawValue ||
      messageType == MessageType.stoppedTyping.rawValue {
      lockConnectionsLock()
      let connectionInfo = connections[from.id]
      unlockConnectionsLock()

      if  connectionInfo != nil {
        echo(message: message)
      }
    }
    else if messageType == MessageType.connected.rawValue {
      guard displayName.count > 0 else {
        from.close(reason: .invalidDataContents, description: "Connect message must have client's name")
        return
      }

      lockConnectionsLock()
      for (_, (clientName,_, _)) in connections {
        from.send(message: "\(MessageType.clientInChat.rawValue):" + clientName)
      }

      connections[from.id] = (displayName, "", from)
      unlockConnectionsLock()

      echo(message: message)
    }
    else {
      invalidData(from: from, description: "First character of the message must be a C, M, S, or T")
    }
  }

  private func echo(message: String) {
    lockConnectionsLock()
    for (_, (_,_, connection)) in connections {
      connection.send(message: message)
    }
    unlockConnectionsLock()
  }

  private func invalidData(from: WebSocketConnection, description: String) {
    from.close(reason: .invalidDataContents, description: description)
    lockConnectionsLock()
    let connectionInfo = connections.removeValue(forKey: from.id)
    unlockConnectionsLock()

    if let (clientName,_, _) = connectionInfo {
      echo(message: "\(MessageType.disconnected.rawValue):\(clientName)")
    }
  }

  private func lockConnectionsLock() {
    _ = connectionsLock.wait(timeout: DispatchTime.distantFuture)
  }

  private func unlockConnectionsLock() {
    connectionsLock.signal()
  }
}

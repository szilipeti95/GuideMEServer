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

  private enum MessageType: String {
    case online = "onl"
    case connect = "con"
    case write = "wri"
    case delete = "del"
    case disconnect = "dis"
    case message = "mes"
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
    // Ignored
    */

    print(connection.id)
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
//        from.send(message: "\(MessageType.disconnected.rawValue):" + disconnectedConnectionData.0)
      }
    }
    unlockConnectionsLock()
  }

  public func received(message: Data, from: WebSocketConnection) {
    invalidData(from: from, description: "Only text messages")
  }

  public func received(message: String, from: WebSocketConnection) {
    guard !message.isEmpty else { return }

    let messageType = String(message.prefix(3))
    if messageType.count < 3 { return }

    let payload = String(message.dropFirst(4))

    switch messageType {
      case MessageType.online.rawValue:
        onlineMessage(email: payload, from: from)
      case MessageType.connect.rawValue:
        connectMessage(otherEmail: payload, from: from)
    case MessageType.write.rawValue:
      writeMessage(from: from)
    case MessageType.delete.rawValue:
      deleteMessage(from: from)
    case MessageType.disconnect.rawValue:
      disconnectMessage(from: from)
    case MessageType.message.rawValue:
      messageMessage(message: payload, from: from)
    default:
      invalidData(from: from, description: "Invalid message")
    }
    /*
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
     */
  }

  private func onlineMessage(email: String, from: WebSocketConnection) {
    lockConnectionsLock()
    /*
    for (_, (clientName,_, _)) in connections {
      //from.send(message: "\(MessageType.clientInChat.rawValue):" + clientName)
    }
    */
    connections[from.id] = (email, "", from)
    unlockConnectionsLock()
  }

  private func connectMessage(otherEmail: String, from: WebSocketConnection) {
    guard let email = connections[from.id]?.0 else {
      return
    }

    lockConnectionsLock()
    connections[from.id] = (email, otherEmail, from)
    unlockConnectionsLock()
  }

  private func writeMessage(from: WebSocketConnection) {
    guard let otherEmail = connections[from.id]?.1 else {
      return
    }
    let otherConnection = getConnectionIdByEmail(email: otherEmail)
    if otherConnection != nil {
      otherConnection?.send(message: "wri")
    }
  }

  private func deleteMessage(from: WebSocketConnection) {
    guard let otherEmail = connections[from.id]?.1 else {
      return
    }

    let otherConnection = getConnectionIdByEmail(email: otherEmail)
    if otherConnection != nil {
      otherConnection?.send(message: "del")
    }
  }

  private func disconnectMessage(from: WebSocketConnection) {
    guard let email = connections[from.id]?.0 else {
      return
    }

    lockConnectionsLock()
    connections[from.id] = (email, "", from)
    unlockConnectionsLock()
  }

  private func messageMessage(message: String, from: WebSocketConnection) {
    guard let otherEmail = connections[from.id]?.1 else {
      return
    }
    guard let senderEmail = connections[from.id]?.0 else {
      return
    }

    let otherConnection = getConnectionIdByEmail(email: otherEmail)

    let messageTable = DBMessage()
    let insertQuery = Insert(into: messageTable,
                             valueTuples: (messageTable.senderEmail, senderEmail),
                             (messageTable.receiverEmail, otherEmail),
                             (messageTable.messageBody, message),
                             (messageTable.timestamp, Int(Date().timeIntervalSince1970)))
    if let connection = pool.getConnection() {
      connection.execute(query: insertQuery) { insertResult in
        print(insertResult)
      }
    }
    if otherConnection != nil {
      otherConnection?.send(message: message)
    } else {
      //pushnotification
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
      //echo(message: "\(MessageType.disconnected.rawValue):\(clientName)")
    }
  }

  private func getConnectionIdByEmail(email: String) -> WebSocketConnection? {
    lockConnectionsLock()
    for(_, (_email, _, connection)) in connections {
      if email == _email {
        unlockConnectionsLock()
        return connection
      }
    }
    unlockConnectionsLock()
    return nil
  }

  private func lockConnectionsLock() {
    _ = connectionsLock.wait(timeout: DispatchTime.distantFuture)
  }

  private func unlockConnectionsLock() {
    connectionsLock.signal()
  }
}

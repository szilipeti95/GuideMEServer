//
//  ChatService.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 06..
//

/*
 TODO: RENAME SENDER / RECEIVER
*/

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
  let sqlDatabase = "guideme_new"
  let pool: ConnectionPool!

  private var connections = [String: ChatConnectionData]()

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
    case delete = "del" //TODO: rename finished
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
      for connection in connections {
//        from.send(message: "\(MessageType.disconnected.rawValue):" + disconnectedConnectionData.0)
      }
    }
    unlockConnectionsLock()
  }

  public func received(message: Data, from: WebSocketConnection) {
    invalidData(from: from, description: "Only text messages")
  }

  public func received(message: String, from connection: WebSocketConnection) {
    guard !message.isEmpty else { return }

    let messageType = String(message.prefix(3))
    if messageType.count < 3 { return }

    let payload = String(message.dropFirst(4))

    switch messageType {
      case MessageType.online.rawValue:
        onlineMessage(email: payload, from: connection)
      case MessageType.connect.rawValue:
        connectMessage(otherEmail: payload, from: connection)
    case MessageType.write.rawValue:
      writeMessage(from: connection)
    case MessageType.delete.rawValue:
      deleteMessage(from: connection)
    case MessageType.disconnect.rawValue:
      disconnectMessage(from: connection)
    case MessageType.message.rawValue:
      messageMessage(message: payload, from: connection)
    default:
      invalidData(from: connection, description: "Invalid message")
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

  private func onlineMessage(email: String, from connection: WebSocketConnection) {
    lockConnectionsLock()
    /*
    for (_, (clientName,_, _)) in connections {
      //from.send(message: "\(MessageType.clientInChat.rawValue):" + clientName)
    }
    */
    connections[connection.id] = ChatConnectionData(email: email,
                                                    connectedToEmail: nil,
                                                    connection: connection)
    unlockConnectionsLock()
  }

  private func connectMessage(otherEmail: String, from connection: WebSocketConnection) {
    lockConnectionsLock()
    connections[connection.id]?.connectedToEmail = otherEmail
    unlockConnectionsLock()
  }

  private func writeMessage(from: WebSocketConnection) {
    guard let otherEmail = connections[from.id]?.connectedToEmail else {
      return
    }
    let otherConnection = getConnectionByEmail(email: otherEmail)
    if otherConnection != nil {
      otherConnection?.send(message: MessageType.write.rawValue)
    }
  }

  private func deleteMessage(from connection: WebSocketConnection) {
    guard let otherEmail = connections[connection.id]?.connectedToEmail else {
      return
    }

    let otherConnection = getConnectionByEmail(email: otherEmail)
    if otherConnection != nil {
      otherConnection?.send(message: "del")
    }
  }

  private func disconnectMessage(from: WebSocketConnection) {
    lockConnectionsLock()
    connections[from.id]?.connectedToEmail = nil
    unlockConnectionsLock()
  }

  private func messageMessage(message: String, from connection: WebSocketConnection) {
    guard let otherEmail = connections[connection.id]?.connectedToEmail,
          let senderEmail = connections[connection.id]?.email else {
      return
    }

    let otherConnection = getConnectionByEmail(email: otherEmail)
    let conversationTable = DBConversation()
    let selectConversationQuery = Select(from: conversationTable).where((conversationTable.user1 == senderEmail && conversationTable.user2 == otherEmail) ||
                                                                        (conversationTable.user1 == otherEmail && conversationTable.user2 == senderEmail))

    let messageTable = DBMessage()
    if let connection = pool.getConnection() {
      connection.execute(query: selectConversationQuery) { selectConversationResult in
        guard let conversationId = selectConversationResult.asRows?.first?[DBConversationColumnNames.conversationId] as? Int32 else {
          return
        }
        let insertQuery = Insert(into: messageTable,
                                 valueTuples: (messageTable.senderEmail, senderEmail),
                                 (messageTable.conversationId, conversationId),
                                 (messageTable.messageBody, message),
                                 (messageTable.timestamp, Int(Date().timeIntervalSince1970)))
        connection.execute(query: insertQuery) { insertResult in
          print(insertResult)
        }
      }
    }
    if otherConnection != nil {
      otherConnection?.send(message: "mes-\(message)")
    } else {
      //pushnotification
    }
  }

  private func echo(message: String) {
    lockConnectionsLock()
    for connection in connections {
      connection.value.connection.send(message: message)
    }
    unlockConnectionsLock()
  }

  private func invalidData(from: WebSocketConnection, description: String) {
    from.close(reason: .invalidDataContents, description: description)
    lockConnectionsLock()
    let connectionData = connections.removeValue(forKey: from.id)
    unlockConnectionsLock()

    if connectionData != nil {
      //echo(message: "\(MessageType.disconnected.rawValue):\(clientName)")
    }
  }

  // MARK: helper functions

  private func getConnectionByEmail(email: String) -> WebSocketConnection? {
    lockConnectionsLock()
    for data in connections {
      if email == data.value.email {
        unlockConnectionsLock()
        return data.value.connection
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

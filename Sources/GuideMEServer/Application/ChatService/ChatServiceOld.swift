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

public class ChatServiceOld: WebSocketService {

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

  enum MessageType: String {
    case becomeOnline = "becomeOnline"
    case openedChat = "openedChat"
    case startedWriting = "startedWriting"
    case stoppedWriting = "stoppedWriting"
    case closedChat = "closedChat"
    case becameOffline = "becameOffline"
    case wroteMessage = "wroteMessage"
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

  public func disconnected(connection: WebSocketConnection, reason: WebSocketCloseReasonCode) {
    lockConnectionsLock()
    guard let senderEmail = connections[connection.id]?.email else {
      return
    }
    if connections.removeValue(forKey: connection.id) != nil {
      let receivers = getOnlineFriends(forEmail: senderEmail)
      for connection in receivers {
        let message = ServiceObject(type: MessageType.becameOffline.rawValue,
                                    sender: senderEmail,
                                    timestamp: Int(Date().timeIntervalSince1970))
        if let data = try? JSONEncoder().encode(message) {
          connection.send(message: data)
        }
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
    case MessageType.becomeOnline.rawValue:
      onlineMessage(email: payload, from: connection)
    case MessageType.openedChat.rawValue:
      connectMessage(otherEmail: payload, from: connection)
    case MessageType.startedWriting.rawValue:
      writeMessage(from: connection)
    case MessageType.stoppedWriting.rawValue:
      deleteMessage(from: connection)
    case MessageType.closedChat.rawValue:
      disconnectMessage(from: connection)
    case MessageType.wroteMessage.rawValue:
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
    let onlineFriends = getOnlineFriends(forEmail: email)

  }

  private func connectMessage(otherEmail: String, from connection: WebSocketConnection) {
    lockConnectionsLock()
    connections[connection.id]?.connectedToEmail = otherEmail
    unlockConnectionsLock()
  }

  private func writeMessage(from connection: WebSocketConnection) {
    guard let otherEmail = connections[connection.id]?.connectedToEmail,
      let senderEmail = connections[connection.id]?.email else {
        return
    }
    let otherConnection = getConnectionByEmail(email: otherEmail)
    if otherConnection != nil {
      let serviceObject = ServiceObject(type: MessageType.startedWriting.rawValue, sender: senderEmail, timestamp: Int(Date().timeIntervalSince1970))
      if let data = try? JSONEncoder().encode(serviceObject) {
        otherConnection?.send(message: data)
      }
    }
  }

  private func deleteMessage(from connection: WebSocketConnection) {
    guard let otherEmail = connections[connection.id]?.connectedToEmail,
      let senderEmail = connections[connection.id]?.email else {
        return
    }

    let otherConnection = getConnectionByEmail(email: otherEmail)
    if otherConnection != nil {
      let serviceObject = ServiceObject(type: "del", sender: senderEmail, timestamp: Int(Date().timeIntervalSince1970))
      if let data = try? JSONEncoder().encode(serviceObject) {
        otherConnection?.send(message: data)
      }
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
        guard let conversationId = selectConversationResult.asRows?.first?[DBConversationColumnNames.conversationId] as? Int64 else {
          return
        }
        let insertQuery = Insert(into: messageTable,
                                 valueTuples: (messageTable.senderEmail, senderEmail),
                                 (messageTable.conversationId, conversationId),
                                 (messageTable.messageBody, message),
                                 (messageTable.timestamp, Date().millisecondsSince1970))
        connection.execute(query: insertQuery) { insertResult in
          print(insertResult)
        }
      }
    }

    if otherConnection != nil {
      let serviceObject = ServiceObject(type: MessageType.wroteMessage.rawValue, sender: senderEmail, timestamp: Int(Date().timeIntervalSince1970))
      serviceObject.payload = message
      if let data = try? JSONEncoder().encode(serviceObject) {
        otherConnection?.send(message: data)
      }
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

  private func getOnlineFriends(forEmail email: String) -> [WebSocketConnection] {
    let conversationTable = DBConversation()
    let selectQuery = Select(from: conversationTable).where((conversationTable.user1 == email && conversationTable.approved == 1)
      || (conversationTable.user2 == email && conversationTable.approved == 1))
    var emails = [String]()
    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        guard let conversations = selectResult.asRows else {
          return
        }
        for conversation in conversations {
          var otherEmail = (conversation[DBConversationColumnNames.user1] as? String)
          if otherEmail != email {
            emails.append(otherEmail!)
          }
          otherEmail = (conversation[DBConversationColumnNames.user2] as? String)
          if otherEmail != email {
            emails.append(otherEmail!)
          }
        }
      }
    }
    var connections = [WebSocketConnection]()
    for otherEmail in emails {
      if let connection = getConnectionByEmail(email: otherEmail) {
        connections.append(connection)
      }
    }
    return connections
  }

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

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

  internal var connections = [String: ChatConnectionData]()

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

  public func connected(connection: WebSocketConnection) {
    print(connection.id)
  }

  public func disconnected(connection: WebSocketConnection, reason: WebSocketCloseReasonCode) {
    guard let senderEmail = connections[connection.id]?.email else {
      return
    }
    let receivers = getOnlineFriends(forEmail: senderEmail)
    lockConnectionsLock()
    if connections.removeValue(forKey: connection.id) != nil {
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

  public func received(message: Data, from connection: WebSocketConnection) {
    guard let serviceObject = try? JSONDecoder().decode(ServiceObject.self, from: message) else {
      return
    }
    if let payload = serviceObject.payload {
      switch serviceObject.type {
      case MessageType.openedChat.rawValue:
        openedChatHandler(otherEmail: payload, from: connection)
      case MessageType.wroteMessage.rawValue:
        wroteMessageHandler(message: payload, from: connection)
      default:
        invalidData(from: connection, description: "Invalid message")
      }
    } else {
      switch serviceObject.type {
      case MessageType.becomeOnline.rawValue:
        becomeOnlineHandler(email: serviceObject.sender, from: connection)
      case MessageType.startedWriting.rawValue:
        startedWritingHandler(from: connection)
      case MessageType.stoppedWriting.rawValue:
        stoppedWritingHandler(from: connection)
      case MessageType.closedChat.rawValue:
        closedChatHandler(from: connection)
      default:
        invalidData(from: connection, description: "Invalid message")
      }
    }
  }

  public func received(message: String, from connection: WebSocketConnection) {
    print(message)
  }

  public func echo(message: String) {
    lockConnectionsLock()
    for connection in connections {
      connection.value.connection.send(message: message)
    }
    unlockConnectionsLock()
  }

  public func invalidData(from: WebSocketConnection, description: String) {
    from.close(reason: .invalidDataContents, description: description)
    lockConnectionsLock()
    let connectionData = connections.removeValue(forKey: from.id)
    unlockConnectionsLock()

    if connectionData != nil {
      //echo(message: "\(MessageType.disconnected.rawValue):\(clientName)")
    }
  }

  // MARK: helper functions

  public func getOnlineFriends(forEmail email: String) -> [WebSocketConnection] {
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

  public func getConnectionByEmail(email: String) -> WebSocketConnection? {
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

  public func lockConnectionsLock() {
    _ = connectionsLock.wait(timeout: DispatchTime.distantFuture)
  }

  public func unlockConnectionsLock() {
    connectionsLock.signal()
  }
}

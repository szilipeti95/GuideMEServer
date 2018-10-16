//
//  ChatServiceMessageHandlers.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 16..
//

import Foundation
import KituraWebSocket
import SwiftKuery

extension ChatService {
  public func becomeOnlineHandler(email: String, from connection: WebSocketConnection) {
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

  public func openedChatHandler(otherEmail: String, from connection: WebSocketConnection) {
    lockConnectionsLock()
    connections[connection.id]?.connectedToEmail = otherEmail
    unlockConnectionsLock()
  }

  public func startedWritingHandler(from connection: WebSocketConnection) {
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

  public func stoppedWritingHandler(from connection: WebSocketConnection) {
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

  public func closedChatHandler(from: WebSocketConnection) {
    lockConnectionsLock()
    connections[from.id]?.connectedToEmail = nil
    unlockConnectionsLock()
  }

  public func wroteMessageHandler(message: String, from connection: WebSocketConnection) {
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
}

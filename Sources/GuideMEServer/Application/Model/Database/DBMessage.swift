//
//  DBMessage.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 07..
//

import Foundation
import SwiftKuery
import SwiftKueryORM
import SwiftKueryMySQL

struct DBMessageColumnNames {
  static let messageId = "message_id"
  static let conversationId = "conversation_id"
  static let senderEmail = "sender"
  static let messageBody = "message"
  static let timestamp = "timestamp"
  static let read = "read"
}

class DBMessage: Table {
  let tableName = "Message"
  let messageId = Column(DBMessageColumnNames.messageId, Int32.self, primaryKey: true, notNull: true)
  let conversationId = Column(DBMessageColumnNames.conversationId, Int32.self, notNull: true)
  let senderEmail = Column(DBMessageColumnNames.senderEmail, String.self, notNull: true)
  let messageBody = Column(DBMessageColumnNames.messageBody, String.self, notNull: true)
  let timestamp = Column(DBMessageColumnNames.timestamp, Int64.self, notNull: true)
  let read = Column(DBMessageColumnNames.read, Int32.self, notNull: true)
}

struct DBMessageModel: Model {
  static var tableName = "Message"
  static var idKeypath: IDKeyPath = \DBMessageModel.messageId

  var messageId: Int?
  var conversationId: Int
  var senderEmail: String
  var messageBody: String
  var timestamp: Int
  var read: Int

  enum CodingKeys: String, CodingKey {
    case messageId = "message_id"
    case conversationId = "conversation_id"
    case senderEmail = "sender"
    case messageBody = "message"
    case timestamp = "timestamp"
    case read = "read"
  }
}

extension DBMessageModel {
  private struct MessagesForConversationFilter: QueryParams {
    let conversationId: Int

    enum CodingKeys: String, CodingKey {
      case conversationId = "conversation_id"
    }
  }

  public static func getMessagesAscending(for conversationId: Int) -> [DBMessageModel]? {
    let wait = DispatchSemaphore(value: 0)
    var messagesForConversation: [DBMessageModel]?

    let filter = MessagesForConversationFilter(conversationId: conversationId)
    DBMessageModel.findAll(matching: filter) { results, error in
      if let error = error {
        print(error)
      } else if let results = results {
        messagesForConversation = results.sorted(by: { $0.timestamp < $1.timestamp })
      }
      wait.signal()
    }
    wait.wait()
    return messagesForConversation
  }

  private struct UpdateReadFilter: QueryParams {
    let conversationId: Int
    let senderEmail: String

    enum CodingKeys: String, CodingKey {
      case conversationId = "conversation_id"
      case senderEmail = "sender"
    }
  }

  public static func updateReadMessages(for conversationId: Int, email: String) -> Bool {
    if var messages = DBMessageModel.getMessagesAscending(for: conversationId) {
      messages = messages.filter({ $0.senderEmail != email })
      messages.forEach { (message) in
        if let messageId = message.messageId {
          var newMessage = message
          newMessage.read = 1
          newMessage.update(id: messageId) { result, error in }
        }
      }
      return true
    } else {
      return false
    }
  }

  public static func getLastMessage(for conversationId: Int) -> DBMessageModel? {
    var lastMessage: DBMessageModel?

    if let messages = getMessagesAscending(for: conversationId) {
      lastMessage = messages.last
    }

    return lastMessage
  }

}

//
//  DBMessage.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 07..
//

import Foundation
import SwiftKuery

struct DBMessageColumnNames {
  static let messageId = "message_id"
  static let conversationId = "conversation_id"
  static let senderEmail = "sender_email"
  static let messageBody = "message_body"
  static let timestamp = "timestamp"
  static let read = "read"
}

class DBMessage : Table {
  let tableName = "Message"
  let messageId = Column(DBMessageColumnNames.messageId, Int32.self, primaryKey: true, notNull: true)
  let conversationId = Column(DBMessageColumnNames.conversationId, Int32.self, notNull: true)
  let senderEmail = Column(DBMessageColumnNames.senderEmail, String.self, notNull: true)
  let messageBody = Column(DBMessageColumnNames.messageBody, String.self, notNull: true)
  let timestamp = Column(DBMessageColumnNames.timestamp, Int64.self, notNull: true)
  let read = Column(DBMessageColumnNames.read, Int32.self, notNull: true)
}

extension DBMessage {
  
}

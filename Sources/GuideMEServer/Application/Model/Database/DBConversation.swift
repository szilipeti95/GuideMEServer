//
//  DBConnected.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 13..
//

import Foundation
import Kitura
import SwiftKuery
import SwiftKueryMySQL

struct DBConversationColumnNames {
  static let conversationId = "conversation_id"
  static let user1 = "user_1"
  static let user2 = "user_2"
  static let approved = "approved"
}

class DBConversation: Table {
  let tableName = "Conversation"
  let conversationId = Column(DBConversationColumnNames.conversationId, Int32.self, primaryKey: true, notNull: true)
  let user1 = Column(DBConversationColumnNames.user1, String.self, notNull: true)
  let user2 = Column(DBConversationColumnNames.user2, String.self, notNull: true)
  let approved = Column(DBConversationColumnNames.approved, Int32.self, notNull: true)
}

extension DBConversation {

}

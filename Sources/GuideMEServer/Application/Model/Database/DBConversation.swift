//
//  DBConnected.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 13..
//

import Foundation
import Kitura
import SwiftKuery
import SwiftKueryORM
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

struct DBConversationModel: Model {
  static var tableName = "Conversation"

  var user1: String
  var user2: String
  var approved: Int

  enum CodingKeys: String, CodingKey {
    case user1 = "user_1"
    case user2 = "user_2"
    case approved = "approved"
  }

}

extension DBConversationModel {
  struct Filter: QueryParams {
    let user_1: String?
    let user_2: String?
    let approved: Int
  }

  public static func getFriendCount(for user: String) -> Int {
    let wait = DispatchSemaphore(value: 0)
    var friendCount = 0

    let filter1 = Filter(user_1: nil, user_2: user, approved: 1)
    let filter2 = Filter(user_1: user, user_2: nil, approved: 1)
    DBConversationModel.findAll(matching: filter1) { results, error in
      guard let results = results else {
        print(error)
        wait.signal()
        return
      }

      friendCount += results.count
      wait.signal()
    }

    wait.wait()

    DBConversationModel.findAll(matching: filter2) { results, error in
      guard let results = results else {
        print(error)
        wait.signal()
        return
      }

      friendCount += results.count
      wait.signal()
    }

    wait.wait()
    return friendCount
  }
}

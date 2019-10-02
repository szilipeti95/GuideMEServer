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

struct DBConversationModel: Model {
  static var tableName = "Conversation"
  static var idKeypath = \DBConversationModel.id

  var id: Int?
  var user1: String
  var user2: String
  var approved: Int

  enum CodingKeys: String, CodingKey {
    case id = "conversation_id"
    case user1 = "user_1"
    case user2 = "user_2"
    case approved = "approved"
  }

}

extension DBConversationModel {
  private struct ConversationFilter: QueryParams {
    let user_1: String?
    let user_2: String?
    let approved: Int?
  }

  public static func getConversations(forEmail userEmail: String, otherEmail: String? = nil, approved: Int? = nil) -> [DBConversationModel]? {
    let wait = DispatchSemaphore(value: 0)
    var conversations: [DBConversationModel]?

    let filter1 = ConversationFilter(user_1: otherEmail, user_2: userEmail, approved: approved)
    let filter2 = ConversationFilter(user_1: userEmail, user_2: otherEmail, approved: approved)
    DBConversationModel.findAll(matching: filter1) { results, error in
      if let error = error {
        print(error)
        conversations = []
      } else if let results = results {
        conversations = results
      }
      wait.signal()
    }
    wait.wait()
    DBConversationModel.findAll(matching: filter2) { results, error in
      if let error = error {
        print(error)
      } else if let results = results {
        conversations?.append(contentsOf: results)
      }
      wait.signal()
    }
    wait.wait()
    return conversations
  }
  
  public static func getUnapprovedConversation(conversationId: Int, email: String) -> DBConversationModel? {
    var unapprovedConversation: DBConversationModel?
    let dbConversations = getConversations(forEmail: email, approved: 0)
    unapprovedConversation = dbConversations?.first(where: { $0.id == conversationId })
    return unapprovedConversation
  }

  public static func getFriendCount(for user: String) -> Int {
    var friendCount = 0

    if let conversations = DBConversationModel.getConversations(forEmail: user, approved: 1) {
      friendCount += conversations.count
    }
    return friendCount
  }
}

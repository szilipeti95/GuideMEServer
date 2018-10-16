//
//  Connected.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 13..
//

import Foundation

class Conversation : Codable {
  var id: Int
  var user: User
  var lastMessage: Message
  var approved: Bool
  var read: Bool

  init(id: Int, user: User, lastMessage: Message, approved: Bool, read: Bool) {
    self.id = id
    self.user = user
    self.lastMessage = lastMessage
    self.approved = approved
    self.read = read
  }

  enum CodingKeys: String, CodingKey {
    case id
    case user
    case lastMessage
    case approved
    case read
  }
}

extension Conversation {
  func toJson() -> String {
    do {
      let jsonEncoder = JSONEncoder()
      let jsonData = try jsonEncoder.encode(self)
      return String(data: jsonData, encoding: .utf8)!
    } catch let decodeError {
      print("Error during JSON decoding: \(decodeError.localizedDescription)")
      return ""
    }
  }
}

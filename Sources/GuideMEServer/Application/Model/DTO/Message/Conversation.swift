//
//  Connected.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 13..
//

import Foundation

class Conversation : Codable {
  var user: User
  var lastMessage: Message
  var approved: Bool

  init(user: User, lastMessage: Message, approved: Bool) {
    self.user = user
    self.lastMessage = lastMessage
    self.approved = approved
  }

  enum CodingKeys: String, CodingKey {
    case user
    case lastMessage
    case approved
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

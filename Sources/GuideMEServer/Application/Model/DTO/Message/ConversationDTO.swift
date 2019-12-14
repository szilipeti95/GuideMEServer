//
//  Connected.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 13..
//

import Foundation

struct ConversationDTO: Codable {
  var id: Int
  var user: UserDTO
  var lastMessage: MessageDTO
  var approved: Bool
  var read: Bool

  enum CodingKeys: String, CodingKey {
    case id
    case user
    case lastMessage
    case approved
    case read
  }
}

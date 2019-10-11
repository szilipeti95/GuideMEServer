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

extension ConversationDTO {
  init(dbConversation: DBConversationModel, user: UserDTO, dbLastMessage: DBMessageModel) {
    self.id = dbConversation.id ?? -1 // TODO: REMOVE?
    self.user = user
    self.lastMessage = MessageDTO(dbMessage: dbLastMessage)
    self.approved = dbConversation.approved == 1
    self.read = dbLastMessage.read == 1
  }
}

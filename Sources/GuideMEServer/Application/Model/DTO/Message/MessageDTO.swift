//
//  Message.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 13..
//

import Foundation

struct MessageDTO: Codable {
  var message: String
  var timestamp: Int
  var sender: String

  enum CodingKeys: String, CodingKey {
    case message
    case timestamp
    case sender
  }
}

extension MessageDTO {
  init(dbMessage: DBMessageModel) {
    self.message = dbMessage.messageBody
    self.timestamp = dbMessage.timestamp / 1000
    self.sender = dbMessage.senderEmail
  }
}

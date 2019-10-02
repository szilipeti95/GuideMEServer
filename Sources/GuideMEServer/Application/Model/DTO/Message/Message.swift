//
//  Message.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 13..
//

import Foundation
import SwiftKuery

struct Message: Codable {
  var message: String
  var timestamp: Int
  var sender: String
  var read: Bool

  enum CodingKeys: String, CodingKey {
    case message
    case timestamp
    case sender
    case read
  }
}

extension Message {
  init(dbMessage: DBMessageModel) {
    self.message = dbMessage.messageBody
    self.timestamp = dbMessage.timestamp
    self.sender = dbMessage.senderEmail
    self.read = dbMessage.read == 1
  }
}

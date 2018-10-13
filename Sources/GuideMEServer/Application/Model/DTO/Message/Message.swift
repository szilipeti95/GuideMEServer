//
//  Message.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 13..
//

import Foundation

class Message : Codable {
  //var user: User   kell?
  var message: String
  var timestamp: Int32

  init(message: String, timestamp: Int32) {
    self.message = message
    self.timestamp = timestamp
  }

  enum CodingKeys: String, CodingKey {
    case message
    case timestamp
  }
}

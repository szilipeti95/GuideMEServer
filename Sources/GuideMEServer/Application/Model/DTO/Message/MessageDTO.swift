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

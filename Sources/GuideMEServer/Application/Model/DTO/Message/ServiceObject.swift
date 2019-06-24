//
//  ServiceObject.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 16..
//

import Foundation

class ServiceObject: Codable {
  var type: String
  var sender: String
  var timestamp: Int
  var payload: String?

  var description: String {
    return "type: \(type) sender: \(sender) timestamp: \(timestamp) payload: \(payload)"
  }

  init(type: String, sender: String, timestamp: Int) {
    self.type = type
    self.sender = sender
    self.timestamp = timestamp
  }

  enum CodingKeys: String, CodingKey {
    case type
    case sender
    case timestamp
    case payload
  }
}

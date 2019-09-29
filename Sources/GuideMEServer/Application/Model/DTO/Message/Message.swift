//
//  Message.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 13..
//

import Foundation
import SwiftKuery

class Message : Codable {
  var message: String
  var timestamp: Int
  var sender: String
  var read: Bool

  init(message: String, timestamp: Int, sender: String, read: Bool) {
    self.message = message
    self.timestamp = timestamp
    self.sender = sender
    self.read = read
  }

  convenience init(dict: [String: Any?]) {
    let message = dict[DBMessageColumnNames.messageBody] as! String
    let timestamp = Int(dict[DBMessageColumnNames.timestamp] as! Int64) / 1000
    let sender = dict[DBMessageColumnNames.senderEmail] as! String
    let read = Bool(dict[DBMessageColumnNames.read] as! Int32)
    self.init(message: message,
              timestamp: timestamp,
              sender: sender,
              read: read)
  }

  enum CodingKeys: String, CodingKey {
    case message
    case timestamp
    case sender
    case read
  }
}

extension Message {
  static func arrayFrom(queryResult: QueryResult) -> [Message]? {
    guard let rows = queryResult.getRows else {
      return nil
    }
    var messageArray = [Message]()
    for row in rows {
      let message = Message(dict: row)
      messageArray.append(message)
    }
    return messageArray
  }
}

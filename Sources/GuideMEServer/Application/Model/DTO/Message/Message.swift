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
  var timestamp: Int32
  var sender: String

  init(message: String, timestamp: Int32, sender: String) {
    self.message = message
    self.timestamp = timestamp
    self.sender = sender
  }

  convenience init(dict: [String: Any?]) {
    let message = dict[DBMessageColumnNames.messageBody] as! String
    let timestamp = dict[DBMessageColumnNames.timestamp] as! Int32
    let sender = dict[DBMessageColumnNames.senderEmail] as! String
    self.init(message: message,
              timestamp: timestamp,
              sender: sender)
  }

  enum CodingKeys: String, CodingKey {
    case message
    case timestamp
    case sender
  }
}

extension Message {
  static func arrayFrom(queryResult: QueryResult) -> [Message]? {
    guard let rows = queryResult.asRows else {
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

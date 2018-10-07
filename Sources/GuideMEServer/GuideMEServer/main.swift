//
//  main.swift
//  CHTTPParser
//
//  Created by Szili Péter on 2018. 09. 15..
//

import Foundation
import Kitura
import Application
import KituraWebSocket

do {
  let app = try Backend()
  try app.run()
  WebSocket.register(service: ChatService(), onPath: "chat-service")
} catch _ {
}


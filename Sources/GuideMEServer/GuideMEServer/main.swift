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
  WebSocket.register(service: ChatService(), onPath: "chat-service")
  let app = try Backend()
  try app.run()
} catch let error {
  print(error)
}


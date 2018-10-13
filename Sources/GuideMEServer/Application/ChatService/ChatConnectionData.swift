//
//  ChatConnectionData.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 13..
//

import Foundation
import KituraWebSocket

struct ChatConnectionData {
  var email: String
  var connectedToEmail: String?
  var connection: WebSocketConnection
}

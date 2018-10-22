//
//  Paths.swift
//  CHTTPParser
//
//  Created by Szili Péter on 2018. 09. 15..
//

import Foundation

class Paths {
  // MARK: Internal
  // MARK: Auth
  static let authRegister = "/auth/register"
  static let authLogin = "/auth/login"
  static let authThirdParty = "/auth/thirdParty"
  // MARK: User
  static let userSelf = "/user/self"
  static let userSelfUpdate = "/user/self/update"
  static let userRandom = "/user/random"
  // MARK: Message
  static let message = "/message/:conversationId"
  static let messagesRead = "/messages/read/:conversationId"
  static let conversation = "/conversations"
  static let approveConversation = "/conversation/approve/:conversationId"
  static let denyConversation = "/conversation/deny/:conversationId"

  //Admin
  static let shutdown = "/shutdown"
}

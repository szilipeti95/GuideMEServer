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
  static let usersData = "/users/:email"
  static let userAvatar = "/user/avatar"
  // MARK: Message
  static let message = "/message/:conversationId"
  static let messagesRead = "/messages/read/:conversationId"
  static let conversation = "/conversations"
  static let approveConversation = "/conversation/approve/:conversationId"
  static let denyConversation = "/conversation/deny/:conversationId"
  static let createConversation = "/conversation/:email"
  // MARK: Images
  static let image = "/image"
  static let imageWithId = "/image/:imageId"
  // MARK: Admin
  static let shutdown = "/shutdown"
}

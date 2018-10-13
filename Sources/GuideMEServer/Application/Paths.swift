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
  // MARK: Message
  static let message = "/message/from=%d"

  //Admin
  static let shutdown = "/shutdown"
}

//
//  JWTMiddleware.swift
//  Application
//
//  Created by Szili Péter on 2018. 09. 23..
//

import Foundation
import Kitura
import SwiftJWT


private let AUTHENTICATED_USER_USER_INFO_KEY = "KITURA_AUTHENTICATED_USER"

class JWTMiddleware: RouterMiddleware {
func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    guard let encodedAndSignedJWT = request.headers["Authorization"] else {
      response.send("Error").status(.badRequest)
      next()
      return
    }
    if try !JWT.verify(encodedAndSignedJWT, using: .rs256(Backend.publicKey, .publicKey)) {
      response.send("Error").status(.unauthorized)
      next()
    }
    guard let user = try? JWT.decode(encodedAndSignedJWT) else {
      response.send("Error").status(.internalServerError)
      next()
      return
    }
    request.authenticatedUser = user?.claims[.nickname] as? String
  }
}

public extension RouterRequest {
  public internal(set) var authenticatedUser: String? {
    get {
      if let authUser = userInfo[AUTHENTICATED_USER_USER_INFO_KEY] as? String {
        return authUser
      }
      return nil
    }
    set {
      userInfo[AUTHENTICATED_USER_USER_INFO_KEY] = newValue
    }
  }
}

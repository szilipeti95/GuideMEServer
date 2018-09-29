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
  /*
  let token: String

  init(token: String) {
    self.token = token
  }

  init() {
    self.token = ""
  }
 */
  /*
  static func handle(request: RouterRequest, response: RouterResponse, completion: @escaping (JWTMiddleware?, RequestError?) -> Void) {
    guard let encodedAndSignedJWT = request.headers["Authorization"] else {
      completion(nil, RequestError(httpCode: 404))
      return
    }
    do {
      if try !JWT.verify(encodedAndSignedJWT, using: .rs256(Backend.publicKey, .publicKey)) {
        completion(nil, RequestError(httpCode: 404))
      }
    } catch(_) {
      completion(nil, RequestError(httpCode: 500))
    }
    let instance = JWTMiddleware(token: encodedAndSignedJWT)
    completion(instance, nil)
  }
  */

  func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    guard let encodedAndSignedJWT = request.headers["Authorization"] else {
      response.send("Error").status(HTTPStatusCode(rawValue: 400)!)
      next()
      return
    }
    if try !JWT.verify(encodedAndSignedJWT, using: .rs256(Backend.publicKey, .publicKey)) {
      response.send("Error").status(HTTPStatusCode(rawValue: 401)!)
      next()
    }
    guard let user = try? JWT.decode(encodedAndSignedJWT) else {
      response.send("Error").status(HTTPStatusCode(rawValue: 500)!)
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

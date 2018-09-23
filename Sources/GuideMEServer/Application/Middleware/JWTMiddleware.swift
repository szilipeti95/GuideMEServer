//
//  JWTMiddleware.swift
//  Application
//
//  Created by Szili Péter on 2018. 09. 23..
//

import Foundation
import Kitura
import SwiftJWT

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
      response.send("Error").status(HTTPStatusCode(rawValue: 400)!)
      next()
    }
  }
}

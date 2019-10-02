//
//  AuthRoutes.swift
//  Application
//
//  Created by Szili Péter on 2018. 09. 15..
//

import CryptoSwift
import Foundation
import Kitura
import SwiftJWT
import SwiftKuery
import SwiftKueryMySQL


func addAuthRoutes(app: Backend) {
  app.router.post(Paths.authRegister, handler: app.registerHandler)
  app.router.post(Paths.authLogin, handler: app.loginHandler)
  app.router.post(Paths.authThirdParty, handler: app.checkHandler)
}

extension Backend {

  //MARK: Register
  fileprivate func registerHandler(register: RegisterRequest, respondWith: @escaping (User?, RequestError?) -> Void) {
    guard register.isValid else {
      return
    }
    let regDate = Int(Date().millisecondsSince1970)
    let passwordHash = register.password.sha256()
    let passwordArray: Array<UInt8> = Array(passwordHash.utf8)
    let saltHash = randomString(length: 64)
    let saltArray: Array<UInt8> = Array(saltHash.utf8)
    let key = PKCS5.generatePassword(passwordArray: passwordArray, saltArray: saltArray)
    let username = generateUsernameFromName(firstName: register.firstName, lastName: register.lastName)
    print("Generated username: \(username)")

    let dbUser = DBUserModel(id: nil,
                             username: username,
                             password: key,
                             salt: saltHash,
                             email: register.email,
                             firstName: register.firstName,
                             lastName: register.lastName,
                             regDate: regDate,
                             avatar: nil,
                             backgroundAvatar: nil)

    dbUser.save { result, error in
      if let error = error {
        print(error)
        respondWith(nil, .internalServerError)
      } else {
        respondWith(nil, nil)
      }
    }
  }

  fileprivate func checkHandler(check: RegisterRequest, respondWith: @escaping (User?, RequestError?) -> Void) {
    if DBUserModel.getUserWith(email: check.email) != nil {
      respondWith(nil, nil)
    } else {
      self.registerHandler(register: check, respondWith: respondWith)
    }
  }

  private func generateUsernameFromName(firstName: String, lastName: String) -> String {
    let username = "\(firstName.lowercased())_\(lastName.lowercased())"

    guard let users = DBUserModel.getUsersWith(firstName: firstName, lastName: lastName) else {
      return username
    }
    return "\(username)\(users.count + 1)"
  }

  fileprivate func loginHandler(login: LoginRequest, respondWith: @escaping (LoginResponse?, RequestError?) -> Void) {
    let passwordHash = login.password.sha256()
    let passwordArray: Array<UInt8> = Array(passwordHash.utf8)

    if let user = DBUserModel.getUserWith(email: login.email) {
      let saltArray: Array<UInt8> = Array(user.salt.utf8)
      let key = PKCS5.generatePassword(passwordArray: passwordArray, saltArray: saltArray)
      if key == user.password {
        var jwt = JWT(header: Header([.typ: "JWT"]), claims: Claims([.email: user.email]))
        guard let signedJWT = try? jwt.sign(using: .rs256(self.privateKey, .privateKey)),
          let strongSignedJWT = signedJWT else {
          respondWith(nil, .internalServerError)
          return
        }
        respondWith(LoginResponse(jwt: strongSignedJWT), nil)
      } else {
        respondWith(nil, .badRequest)
      }
    }
  }
}

fileprivate func randomString(length: Int) -> String {
  let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  let len = UInt32(letters.length)

  var randomString = ""

  for _ in 0 ..< length {
    #if os(Linux)
    let rand = Int(random() % Int(len))
    #else
    let rand =  arc4random_uniform(len)
    #endif
    var nextChar = letters.character(at: Int(rand))
    randomString += String(describing: NSString(characters: &nextChar, length: 1))
  }

  return randomString
}


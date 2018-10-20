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
    let user = DBUser()
    let username = generateUsernameFromName(firstName: register.firstName, lastName: register.lastName)
    print("Generated username: \(username)")
    let insertQuery = Insert(into: user, valueTuples: (user.username, username),
                             (user.password, key),
                             (user.salt, saltHash),
                             (user.email, register.email),
                             (user.firstName, register.firstName),
                             (user.lastName, register.lastName),
                             (user.regDate, regDate))
    if let connection = pool.getConnection() {
      connection.execute(query: insertQuery) { insertResult in
        if let error = insertResult.asError {
          print(error)
          respondWith(nil, .internalServerError)
        } else {
          respondWith(nil, nil)
        }
      }
    }
  }

  fileprivate func checkHandler(check: RegisterRequest, respondWith: @escaping (User?, RequestError?) -> Void) {
    let userTable = DBUser()
    let selectQuery = Select(from: userTable).where(userTable.email == check.email)
    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        guard let rowCount = selectResult.asRows?.count else {
          respondWith(nil, .internalServerError)
          return
        }
        if rowCount == 0 {
          self.registerHandler(register: check, respondWith: respondWith)
          return
        } else {
          respondWith(nil, nil)
          return
        }
      }
    }
  }

  private func generateUsernameFromName(firstName: String, lastName: String) -> String {
    let userTable = DBUser()
    var username = "\(firstName.lowercased())_\(lastName.lowercased())"
    let selectQuery = Select(from: userTable).where(userTable.firstName == firstName && userTable.lastName == userTable.lastName)
    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        if let number = selectResult.asRows?.count {
          username = "\(username)\(number+1)"
        }
      }
    }
    return username
  }

  fileprivate func loginHandler(login: LoginRequest, respondWith: @escaping (LoginResponse?, RequestError?) -> Void) {
    let passwordHash = login.password.sha256()
    let passwordArray: Array<UInt8> = Array(passwordHash.utf8)

    let userTable = DBUser()
    let selectQuery = Select(from: userTable).where(userTable.email == login.email)

    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        print(selectResult)
        guard selectResult.success, let selected = selectResult.asRows?.first else {
          print(selectResult.asError as Any)
          respondWith(nil, .badRequest)
          return
        }
        print(selected)
        let userPassword = selected["password"] as! String
        let userSalt = selected["salt"] as! String

        let saltArray: Array<UInt8> = Array(userSalt.utf8)
        do {
          let key = PKCS5.generatePassword(passwordArray: passwordArray, saltArray: saltArray)
          if key == userPassword {
            var jwt = JWT(header: Header([.typ:"JWT"]),
                          claims: Claims([.email: login.email]))
            guard let signedJWT = try jwt.sign(using: .rs256(self.privateKey, .privateKey)) else {
              respondWith(nil, .internalServerError)
              return
            }
            respondWith(LoginResponse(jwt: signedJWT), nil)
          } else {
            respondWith(nil, .badRequest)
            return
          }
        } catch _ {
          respondWith(nil, .internalServerError)
        }
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


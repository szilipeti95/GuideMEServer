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
  app.router.all(Paths.authRegister, middleware: BodyParser())
  app.router.post(Paths.authRegister, handler: app.registerHandler)

  app.router.all(Paths.authLogin, middleware: BodyParser())
  app.router.post(Paths.authLogin, handler: app.loginHandler)
}

extension Backend {

  //MARK: Register
  fileprivate func registerHandler(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) {
    guard let jsonBody = request.body?.asJSON else {
      response.send(request.body?.asText)
      next()
      return
    }

    let username = jsonBody[DBUserColumnNames.username] as? String ?? ""
    let email = jsonBody[DBUserColumnNames.email] as? String ?? ""
    let password = jsonBody[DBUserColumnNames.password] as? String ?? ""

    if username == "" || email == "" || password == "" {
      response.send("error")
      next()
    }

    let regDate = Int(Date().timeIntervalSince1970)
    let passwordHash = password.sha256()
    let passwordArray: Array<UInt8> = Array(passwordHash.utf8)
    let saltHash = randomString(length: 64)
    let saltArray: Array<UInt8> = Array(saltHash.utf8)
    let key = PKCS5.generatePassword(passwordArray: passwordArray, saltArray: saltArray)
    let user = DBUser()
    let insertQuery = Insert(into: user, valueTuples: (user.username, username),
                             (user.password, key),
                             (user.salt, saltHash),
                             (user.email, email),
                             (user.regDate, regDate))
    if let connection = pool.getConnection() {
      connection.execute(query: insertQuery) { insertResult in
        if let error = insertResult.asError {
          print(error)
          response.send("error")
          next()
          return
        } else {
          response.send("siker")
          next()
        }
      }
    }
  }

  //MARK: Login
  fileprivate func loginHandler(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) {
    guard let jsonBody = request.body?.asJSON else {
      response.send(request.body?.asText)
      next()
      return
    }
    let username = jsonBody["username"] as? String ?? ""
    let password = jsonBody["password"] as? String ?? ""
    let passwordHash = password.sha256()
    let passwordArray: Array<UInt8> = Array(passwordHash.utf8)

    let user = DBUser()
    let selectQuery = Select(from: user).where(user.username == username)

    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        guard selectResult.success, let selected = selectResult.asRows?.first else {
          print(selectResult.asError as Any)
          return
        }

        let userPassword = selected["password"] as! String
        let userSalt = selected["salt"] as! String

        let saltArray: Array<UInt8> = Array(userSalt.utf8)
        do {
          let key = PKCS5.generatePassword(passwordArray: passwordArray, saltArray: saltArray)
          if key == userPassword {
            var jwt = JWT(header: Header([.typ:"JWT"]),
                          claims: Claims([.nickname: username]))
            let signedJWT = try jwt.sign(using: .rs256(self.privateKey, .privateKey))
            response.send("authorized: \(user.username) signedJWT: \(signedJWT ?? "nincs")")
            next()
            return
          } else {
            response.send("wrong pass")
            next()
            return
          }
        } catch _ {
          response.send("error during key generation")
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


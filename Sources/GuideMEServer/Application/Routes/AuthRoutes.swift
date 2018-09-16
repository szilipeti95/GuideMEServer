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

  //MARK: AUTH REGISTER

  app.router.all("/auth/register", middleware: BodyParser())
  app.router.post("/auth/register") {
    request, response, next in

    guard let jsonBody = request.body?.asJSON else {
      response.send(request.body?.asText)
      next()
      return
    }

    let username = jsonBody["username"] as? String ?? ""
    let email = jsonBody["email"] as? String ?? ""
    let password = jsonBody["password"] as? String ?? ""

    if username == "" || email == "" || password == "" {
      response.send("error")
      next()
    }

    let regDate = Int(Date().timeIntervalSince1970)
    let passwordHash = password.sha256()
    let passwordArray: Array<UInt8> = Array(passwordHash.utf8)
    let saltHash = randomString(length: 64)
    let saltArray: Array<UInt8> = Array(saltHash.utf8)
    let key = try PKCS5.PBKDF2.init(password: passwordArray, salt: saltArray, iterations: 4096, keyLength: 32, variant: .sha256).calculate().toHexString()
    print(key)
    let user = User()
    let insertQuery = Insert(into: user, valueTuples: (user.username, username),
                             (user.password, key),
                             (user.salt, saltHash),
                             (user.email, email),
                             (user.regDate, regDate))
    if let connection = app.pool.getConnection() {
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

  //MARK: AUTH LOGIN

  app.router.all("/auth/login", middleware: BodyParser())
  app.router.post("/auth/login") {
    request, response, next in

    guard let jsonBody = request.body?.asJSON else {
      response.send(request.body?.asText)
      next()
      return
    }
    let username = jsonBody["username"] as? String ?? ""
    let password = jsonBody["password"] as? String ?? ""
    let passwordHash = password.sha256()
    let passwordArray: Array<UInt8> = Array(passwordHash.utf8)

    let user = User()
    let selectQuery = Select(from: user).where(user.username == username)

    if let connection = app.pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        guard selectResult.success else {
          print(selectResult.asError)
          return
        }
        guard let selected = selectResult.asRows?.first else {
          print("internal error")
          return
        }
        let userUsername = selected["username"] as! String
        let userEmail = selected["email"] as! String
        let userPassword = selected["password"] as! String
        let userSalt = selected["salt"] as! String
        let userFirstName = selected["first_name"] as! String
        let userLastName = selected["last_name"] as! String
        let userRegDate = selected["reg_date"] as! Int
        let userAvatar = selected["avatar"] as! String
        let userBackgroundAvatar = selected["background_avatar"] as! String

        let saltArray: Array<UInt8> = Array(userSalt.utf8)
        do {
          let key = try PKCS5.PBKDF2.init(password: passwordArray, salt: saltArray, iterations: 4096, keyLength: 32, variant: .sha256).calculate().toHexString()

          if key == userPassword {
            let jsonEncoder = JSONEncoder()
            do {
              let sendUser = SendUser(username: userUsername,
                                      email: userEmail,
                                      fistName: userFirstName,
                                      lastLame: userLastName,
                                      regDate: userRegDate,
                                      avatar: userAvatar,
                                      backgroundAvatar: userBackgroundAvatar)
              let jsonData = try jsonEncoder.encode(sendUser)
              let jsonString = String(data: jsonData, encoding: .utf8)
              var jwt = JWT(header: Header([.typ:"JWT"]),
                            claims: Claims([.aud: jsonString!]))
              let keyPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath + "/privateKey.key")
              print(keyPath.absoluteString)
              let key: Data = try Data(contentsOf: keyPath, options: .alwaysMapped)
              let signedJWT = try jwt.sign(using: .rs256(key, .privateKey))
              response.send("authorized: \(user.username) signedJWT: \(signedJWT ?? "nincs")")
              next()
              return
            }
            catch {
            }
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


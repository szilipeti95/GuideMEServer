//
//  UserRoutes.swift
//  Application
//
//  Created by Szili Péter on 2018. 09. 16..
//

import Foundation
import Kitura
import SwiftJWT
import SwiftKuery
import SwiftKueryMySQL

func addUserRoutes(app: Backend) {
  app.router.get(Paths.userSelf, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.get(Paths.userSelf, handler: app.getUserHandler)
  app.router.get(Paths.userRandom, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.get(Paths.userRandom, handler: app.getFourRandomHandler          )
  app.router.put(Paths.userSelfUpdate, middleware: BodyParser())
  app.router.put(Paths.userSelfUpdate, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.put(Paths.userSelfUpdate, handler: app.updateUserInfoHandler)
}

extension Backend {
  fileprivate func getUserHandler(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser else {
      return
    }
    let userTable = DBUser()
    let selectQuery = Select(from: userTable).where(userTable.email == email)

    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        guard selectResult.success, let selected = selectResult.asRows?.first else {
          print(selectResult.asError as Any)
          return
        }
        let userResponse = User(dict: selected)
        try? response.send(userResponse.toJson()).end()
      }
    } else {
      try? response.send("Error").status(.internalServerError).end()
    }
  }

  fileprivate func getFourRandomHandler(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser else {
      return
    }
    let userTable = DBUser()
    let selectQuery = Select(from: userTable).where(userTable.email != email)
    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        guard let rows = selectResult.asRows else {
          response.send("").status(.internalServerError); next()
          return
        }
        let length = UInt32(rows.count)
        var users = [User]()
        for _ in 1...4 {
          #if os(Linux)
          let rand = Int(random() % Int(length))
          #else
          let rand =  arc4random_uniform(length)
          #endif
          let row = rows[Int(rand)]
          let user = User(dict: row)
          users.append(user)
        }
        guard let jsonData = try? JSONEncoder().encode(users) else {
          print("Error during JSON decoding")
          response.send("").status(.internalServerError)
          next()
          return
        }
        let jsonString = String(data: jsonData, encoding: .utf8)!
        response.send(jsonString)
        next()
      }
    }
  }

  fileprivate func updateUserInfoHandler(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser else {
      return
    }
    let userTable = DBUser()
    let selectQuery = Select(from: userTable).where(userTable.email == email)

    guard let body = request.body?.asJSON else {
      response.send("Error").status(.badRequest)
      next()
      return
    }
    let updateUser = User(dict: body)
    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        guard selectResult.success, let selected = selectResult.asRows?.first else {
          response.send("Error").status(.internalServerError)
          return
        }
        var user = DBUserObject.convertFrom(dict: selected)
        user.firstName = updateUser.firstName
        user.lastName = updateUser.lastName
        user.username = updateUser.username
        user.email = updateUser.email
        let updateQuery = Update(userTable, set: user.foo()).where(userTable.email == email)
        connection.execute(query: updateQuery) { updateResult in
          guard updateResult.success else {
            response.send("Error").status(.internalServerError)
            next()
            return
          }
          response.send("sendUser.toJson()")
          next()
        }
      }
    }
  }
}

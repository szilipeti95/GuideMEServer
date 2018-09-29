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
  app.router.get(Paths.userSelf, allowPartialMatch: false, middleware: JWTMiddleware())
  app.router.get(Paths.userSelf, handler: app.getUserHandler)
  app.router.put("user/self/update", middleware: BodyParser())
  app.router.put("user/self/update", allowPartialMatch: false, middleware: JWTMiddleware())
  app.router.put("user/self/update", handler: app.updateUserInfoHandler)
}

extension Backend {
  fileprivate func getUserHandler(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let username = request.authenticatedUser else {
      return
    }
    let userTable = DBUser()
    let selectQuery = Select(from: userTable).where(userTable.username == username)

    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        guard selectResult.success, let selected = selectResult.asRows?.first else {
          print(selectResult.asError as Any)
          return
        }
        let sendUser = SendUser.createFrom(dict: selected)
        try? response.send(sendUser.toJson()).end()
      }
    } else {
      try? response.send("Error").status(.internalServerError).end()
    }
  }

  fileprivate func updateUserInfoHandler(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let username = request.authenticatedUser else {
      return
    }
    let userTable = DBUser()
    let selectQuery = Select(from: userTable).where(userTable.username == username)

    guard let body = request.body?.asJSON else {
      print("body")
      response.send("Error").status(.badRequest)
      next()
      return
    }
    let updateUser = SendUser.createFrom(dict: body)
    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        guard selectResult.success, let selected = selectResult.asRows?.first else {
          response.send("Error").status(.internalServerError)
          return
        }
        var user = DBUserObject.convertFrom(dict: selected)
        user.firstName = updateUser.firstName
        user.lastName = updateUser.lastName
        let updateQuery = Update(userTable, set: user.foo()).where(userTable.username == username)
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
/*
  fileprivate func updateUserPasswordHandler(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard try validateJwtIn(request: request), let header = request.headers["Authorization"] else {
      response.send("Authorization Error")
      next()
      return
    }

    let username = try JWT.decode(header)?.claims[.nickname] as! String
    guard let password = request.body?.asJSON?["password"] as? String else {
      response.send("No body")
      next()
      return
    }

    let user = DBUser()
    let selectQuery = Select(from: user).where(user.username == username)
  }
 */
}

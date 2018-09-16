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
  app.router.get("/user/self", handler: app.getUserHandler)
}

extension Backend {
  fileprivate func getUserHandler(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard try validateJwtIn(request: request), let header = request.headers["Authorization"] else {
      response.send("Authorization Error")
      next()
      return
    }
    let username = try JWT.decode(header)?.claims[.nickname] as! String
    let user = User()
    let selectQuery = Select(from: user).where(user.username == username)

    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        guard selectResult.success, let selected = selectResult.asRows?.first else {
          print(selectResult.asError as Any)
          return
        }
        let sendUser = User.convertForSend(user: selected)
        response.send(sendUser.toJson())
        next()
      }
    }

  }
}

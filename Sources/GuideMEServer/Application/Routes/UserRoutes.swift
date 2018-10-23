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
  app.router.get(Paths.usersData, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.get(Paths.usersData, handler: app.getUsersDataHandler)
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

    if let userData = getUserData(for: email) {
      try? response.send(userData.toJson()).end()
    } else {
      response.send("").status(.badRequest); next()
      return
    }
    /*
    let userTable = DBUser()
    let selectQuery = Select(from: userTable).where(userTable.email == email)

    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        guard selectResult.success, let selected = selectResult.asRows?.first else {
          print(selectResult.asError as Any)
          return
        }
        let userResponse = User(dict: selected)
        let photosTable = DBUserPhotos()
        let selectPhotosQuery = Select(from: photosTable).where(photosTable.userEmail == email).order(by: .DESC(photosTable.timestamp))
        connection.execute(query: selectPhotosQuery) { selectPhotosResult in
          guard let rows = selectPhotosResult.asRows else {
            response.send("").status(.internalServerError); next()
            return
          }
          if rows.count != 0 {
            var photos = [Photo]()
            for row in rows {
              photos.append(Photo(dict: row))
            }
            userResponse.photos = photos
          }
        }
        try? response.send(userResponse.toJson()).end()
      }
    } else {
      try? response.send("Error").status(.internalServerError).end()
    }
     */
  }

  fileprivate func getUsersDataHandler(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard request.authorizedUser != nil else {
      response.send("").status(.unauthorized); next()
      return
    }
    guard let email = request.parameters["email"] else {
      response.send("").status(.badRequest); next()
      return
    }

    if let userData = getUserData(for: email) {
      try? response.send(userData.toJson()).end()
    } else {
      response.send("").status(.badRequest); next()
      return
    }
  }

  internal func getUserData(for email: String) -> User? {
    let userTable = DBUser()
    let selectQuery = Select(from: userTable).where(userTable.email == email)
    var user: User? = nil
    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        guard selectResult.success, let selected = selectResult.asRows?.first else {
          print(selectResult.asError as Any)
          return
        }
        let userResponse = User(dict: selected)
        let photosTable = DBUserPhotos()
        let selectPhotosQuery = Select(from: photosTable).where(photosTable.userEmail == email).order(by: .DESC(photosTable.timestamp))
        connection.execute(query: selectPhotosQuery) { selectPhotosResult in
          guard let rows = selectPhotosResult.asRows else {
            return
          }
          if rows.count != 0 {
            var photos = [Photo]()
            for row in rows {
              photos.append(Photo(dict: row))
            }
            userResponse.photos = photos
          }
          let conversaionTable = DBConversation()
          let selectFriendsQuery = Select(from: conversaionTable).where((conversaionTable.user1 == email || conversaionTable.user2 == email) &&
                                                                        conversaionTable.approved == 1)
          connection.execute(query: selectFriendsQuery) { selectFriendsResult in
            guard let count = selectFriendsResult.asRows?.count else {
              return
            }
            userResponse.friendCount = count
          }
          user = userResponse
        }
      }
    }
    return user
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
          let email = rows[Int(rand)]["email"] as! String
          if let user = self.getUserData(for: email) {
            users.append(user)
          }
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
    
  }
}

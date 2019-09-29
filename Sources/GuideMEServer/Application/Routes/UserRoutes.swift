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
  app.router.get(Paths.userRandom, handler: app.getFourRandomHandler)

  app.router.put(Paths.userSelfUpdate, middleware: BodyParser())
  app.router.put(Paths.userSelfUpdate, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.put(Paths.userSelfUpdate, handler: app.updateUserInfoHandler)

  app.router.post("/user/avatar", middleware: BodyParser())
  app.router.post("/user/avatar", allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.post("/user/avatar", handler: app.uploadProfileImage)

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
    pool.getConnection() { connection, error in
      guard let connection = connection else { return }
      connection.execute(query: selectQuery) { selectResult in
        guard selectResult.success, let selected = selectResult.getRows?.first else {
          print(selectResult.asError as Any)
          return
        }
        let userResponse = User(dict: selected)
        let photosTable = DBUserPhotos()
        let selectPhotosQuery = Select(from: photosTable).where(photosTable.userEmail == email).order(by: .DESC(photosTable.timestamp))
        connection.execute(query: selectPhotosQuery) { selectPhotosResult in
          guard let rows = selectPhotosResult.getRows else {
            return
          }
          if rows.count != 0 {
            var photos = [Photo]()
            for row in rows {
              if (row["photo_uri"] as! String).contains("image") {
                photos.append(Photo(dict: row))
              }
            }
            userResponse.photos = photos
          }
          let conversaionTable = DBConversation()
          let selectFriendsQuery = Select(from: conversaionTable).where((conversaionTable.user1 == email || conversaionTable.user2 == email) &&
                                                                        conversaionTable.approved == 1)
          connection.execute(query: selectFriendsQuery) { selectFriendsResult in
            guard let count = selectFriendsResult.getRows?.count else {
              return
            }
            userResponse.friendCount = count
          }
          let citiesTable = DBCities()
          let guidesTable = DBGuides()
          let selectLocal = Select(from: guidesTable).leftJoin(citiesTable).on(guidesTable.cityId == citiesTable.citiesId).where(guidesTable.type == 0 && guidesTable.userEmail == email)
          connection.execute(query: selectLocal) { selectLocalResult in
            if let rows = selectLocalResult.getRows {
              if rows.count > 0 {
                let row = rows[0]
                let city = City(dict: row)
                userResponse.local = city
              }
            }

          }
          let selectNext = Select(from: guidesTable).leftJoin(citiesTable).on(guidesTable.cityId == citiesTable.citiesId).where(guidesTable.type == 1 && guidesTable.userEmail == email).order(by: .ASC(guidesTable.from))
          connection.execute(query: selectNext) { selectNextResult in
            if let rows = selectNextResult.getRows {
              if rows.count > 0 {
                let row = rows[0]
                let city = City(dict: row)
                userResponse.next = city
              }
            }
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
    pool.getConnection() { connection, error in
      guard let connection = connection else { return }
      connection.execute(query: selectQuery) { selectResult in
        guard let rows = selectResult.getRows else {
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

  fileprivate func uploadProfileImage(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let parts = request.body?.asMultiPart,
      let email = request.authorizedUser else {
        return
    }
    let imagePart = parts.filter { $0.type.contains("image") }.first
    let descriptionPart = parts.filter { $0.name == "description" }.first
    let userPhotosTable = DBUserPhotos()
    let selectQuery = Select(from: userPhotosTable)
    pool.getConnection() { connection, error in
      guard let connection = connection else { return }
      connection.execute(query: selectQuery) { selectResult in
        guard let count = selectResult.getRows?.count,
          let data = imagePart?.body.asRaw else {
            return
        }
        let dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let fileName = "profile-\(email)-\(count)"
        let fileURL = dir.appendingPathComponent(fileName)
        let description = descriptionPart?.body.asText
        do {
          try data.write(to: fileURL, options: .atomic)
        }
        catch let error {
          print(error)
        }
        var valueTuples: [(Column, Any)] = [(userPhotosTable.userEmail, email),
                                            (userPhotosTable.photoUri, fileName),
                                            (userPhotosTable.timestamp, Date().millisecondsSince1970)]
        if let description = description {
          valueTuples.append((userPhotosTable.description, description))
        }
        let insertQuery = Insert(into: userPhotosTable, valueTuples: valueTuples)
        connection.execute(query: insertQuery) { insertResult in
          let userTable = DBUser()
          let tuples: [(Column, Any)] = [(userTable.avatar, fileName)]
          let updateQuery = Update(userTable, set: tuples).where(userTable.email == email)
          connection.execute(query: updateQuery) { updateQueryResult in

          }
          print(insertResult)
          response.send("Success")
          next()
        }
      }
    }
  }

  fileprivate func updateUserInfoHandler(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser else {
      return
    }
    
  }
}

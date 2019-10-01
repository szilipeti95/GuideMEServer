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
    guard let user = DBUserModel.getUserWith(email: email) else { return nil }

    var userResponse = User(dbUser: user)
    userResponse.photos = DBUserPhotosModel.getUploadedPhotosFor(userEmail: email)?.map({ Photo(photo: $0) })
    userResponse.friendCount = DBConversationModel.getFriendCount(for: email)

    if let selectLocal = DBGuidesModel.getLocalGuide(for: email),
      let localCity = DBCitiesModel.getCity(with: selectLocal.cityId) {
      userResponse.local = City(dbCity: localCity)

    }
    if let selectNext = DBGuidesModel.getNextGuide(for: email),
      let nextCity = DBCitiesModel.getCity(with: selectNext.cityId) {
      userResponse.next = City(dbCity: nextCity)
    }

    return userResponse
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
      let email = request.authorizedUser,
      let imageData = parts.filter({ $0.type.contains("image") }).first?.body.asRaw,
      let count = DBUserPhotosModel.getUploadedPhotosCount() else {
        return
    }

    let description = parts.filter { $0.name == "description" }.first?.body.asText
    let dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let fileName = "profile-\(email)-\(count)"
    let fileURL = dir.appendingPathComponent(fileName)
    try? imageData.write(to: fileURL, options: .atomic)

    let dbPhoto = DBUserPhotosModel(id: nil,
                                    userEmail: email,
                                    photoUri: fileName,
                                    description: description,
                                    likeCount: 0,
                                    timestamp: Date().millisecondsSince1970)

    dbPhoto.save { result, error in
      if var dbUser = DBUserModel.getUserWith(email: email) {
        dbUser.avatar = fileName
        dbUser.update(id: dbUser.id) { result, error in
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

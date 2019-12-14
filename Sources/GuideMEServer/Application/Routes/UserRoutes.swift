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

  app.router.post(Paths.userAvatar, middleware: BodyParser())
  app.router.post(Paths.userAvatar, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.post(Paths.userAvatar, handler: app.uploadProfileImage)
}

extension Backend {
  fileprivate func getUserHandler(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let user = request.authorizedUser else { return }
    try response.send(json: user).end(); next()
  }

  fileprivate func getUsersDataHandler(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard request.authorizedUser != nil else { return }
    guard let email = request.parameters["email"] else {
      response.send("").status(.badRequest); next()
      return
    }

    if let userData = UserDTO.builder(email: email) {
      try response.send(json: userData).end(); next()
    } else {
      try response.send(status: .badRequest).end(); next()
    }
  }

  fileprivate func getFourRandomHandler(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let user = request.authorizedUser else {
      return
    }

    if let otherUsers = DBUserModel.getOtherUsers(from: user.email) {
      let randomNumbers = uniqueRandoms(numberOfRandoms: 4, minNum: 0, maxNum: otherUsers.count - 1)
      var users = [UserDTO]()
      randomNumbers.forEach { randomNumber in
        let otherUser = otherUsers[randomNumber]
        guard let otherUserData = UserDTO.builder(email: otherUser.email) else { return }
        users.append(otherUserData)
      }
      try response.send(json: users).end(); next()
    } else {
      try response.send(status: .internalServerError).end(); next()
    }
  }

  fileprivate func uniqueRandoms(numberOfRandoms: Int, minNum: Int, maxNum: Int) -> [Int] {
    var uniqueNumbers = Set<Int>()
    while uniqueNumbers.count < numberOfRandoms {
      #if os(Linux)
      uniqueNumbers.insert(Int(random() % Int(maxNum+1) + minNum))
      #else
      uniqueNumbers.insert(Int(arc4random_uniform(UInt32(maxNum + 1))) + minNum)
      #endif
    }
    return Array(uniqueNumbers)
  }

  fileprivate func uploadProfileImage(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let parts = request.body?.asMultiPart,
      let user = request.authorizedUser,
      let imageData = parts.filter({ $0.type.contains("image") }).first?.body.asRaw,
      let count = DBUserPhotosModel.getUploadedPhotosCount() else {
        return
    }
    let email = user.email //!!!!

    let description = parts.filter { $0.name == "description" }.first?.body.asText
    let dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let fileName = "profile-\(email)-\(count)"
    let fileURL = dir.appendingPathComponent(fileName)
    try imageData.write(to: fileURL, options: .atomic)

    let dbPhoto = DBUserPhotosModel(id: nil,
                                    userEmail: email,
                                    photoUri: fileName,
                                    description: description,
                                    likeCount: 0,
                                    timestamp: Date().millisecondsSince1970)

    dbPhoto.save { result, error in
      if var dbUser = DBUserModel.getUserWith(email: email), let id = dbUser.id {
        dbUser.avatar = fileName
        dbUser.update(id: id) { result, error in
          try? response.send("Success").end(); next()
        }
      }
    }
  }

  fileprivate func updateUserInfoHandler(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser else {
      return
    }
    print(email)
  }
}

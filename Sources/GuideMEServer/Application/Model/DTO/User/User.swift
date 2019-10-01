//
//  UserResponse.swift
//  Application
//
//  Created by Szili Péter on 2018. 09. 29..
//

import Foundation
import SwiftKuery
import SwiftKueryORM

struct User : Codable {
  var username: String
  var email: String
  var firstName: String
  var lastName: String
  var regDate: Int
  var avatar: String?
  var backgroundAvatar: String?
  var photos: [Photo]?
  var bio: String?
  var local: City?
  var next: City?
  var friendCount: Int

  init(username: String,
       email: String,
       firstName: String,
       lastName: String,
       regDate: Int,
       avatar: String?,
       backgroundAvatar: String?,
       bio: String?) {
    self.username = username
    self.email = email
    self.firstName = firstName
    self.lastName = lastName
    self.regDate = regDate
    self.avatar = avatar
    self.backgroundAvatar = backgroundAvatar
    self.bio = bio
    self.friendCount = 0
  }

  init(dbUser: DBUserModel) {
    self.username = dbUser.username
    self.email = dbUser.email
    self.firstName = dbUser.firstName
    self.lastName = dbUser.lastName
    self.regDate = dbUser.regDate
    self.avatar = dbUser.avatar
    self.backgroundAvatar = dbUser.backgroundAvatar
//    self.bio = dbUser.bio
    self.friendCount = 0
  }

  enum CodingKeys: String, CodingKey {
    case username = "username"
    case email = "email"
    case firstName = "first_name"
    case lastName = "last_name"
    case regDate = "reg_date"
    case avatar = "avatar"
    case backgroundAvatar = "background_avatar"
    case photos = "photos"
    case bio
    case local
    case next
    case friendCount = "friend_count"
  }
}
/*
extension User: Model {
  public static func getFirstWith(email: String) -> User? {
    guard let table = try? User.getTable() else { return nil }

    var userWithEmail: User? = nil
    let query = Select(from: table).where("email == \(email)")

    let wait = DispatchSemaphore(value: 0)
    User.executeQuery(query: query) { results, error in
      guard let results = results else {
        return
      }
      userWithEmail = results.first
      wait.signal()
      return
    }
    wait.wait()
    return userWithEmail
  }
}
*/
extension User {
  func toJson() -> String {
    do {
      let jsonEncoder = JSONEncoder()
      let jsonData = try jsonEncoder.encode(self)
      return String(data: jsonData, encoding: .utf8)!
    } catch let decodeError {
      print("Error during JSON decoding: \(decodeError.localizedDescription)")
      return ""
    }
  }

  init(dict: [String: Any?]) {
    let userUsername = dict["username"] as! String
    let userEmail = dict["email"] as! String
    let userFirstName = dict["first_name"] as! String
    let userLastName = dict["last_name"] as! String
    let userRegDate = Int(dict["reg_date"] as! Int64) / 1000
    let userAvatar = dict["avatar"] as? String
    let userBackgroundAvatar = dict["background_avatar"] as? String
    let bio = dict["bio"] as? String

    self.init(username: userUsername,
                email: userEmail,
                firstName: userFirstName,
                lastName: userLastName,
                regDate: userRegDate,
                avatar: userAvatar,
                backgroundAvatar: userBackgroundAvatar,
                bio: bio)
  }
}


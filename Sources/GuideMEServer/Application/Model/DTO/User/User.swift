//
//  UserResponse.swift
//  Application
//
//  Created by Szili Péter on 2018. 09. 29..
//

import Foundation


class User : Codable {
  var username: String
  var email: String
  var firstName: String?
  var lastName: String?
  var regDate: Int32
  var avatar: String?
  var backgroundAvatar: String?

  init(username: String,
       email: String,
       firstName: String?,
       lastName: String?,
       regDate: Int32,
       avatar: String?,
       backgroundAvatar: String?) {
    self.username = username
    self.email = email
    self.firstName = firstName
    self.lastName = lastName
    self.regDate = regDate
    self.avatar = avatar
    self.backgroundAvatar = backgroundAvatar
  }

  enum CodingKeys: String, CodingKey {
    case username = "username"
    case email = "email"
    case firstName = "first_name"
    case lastName = "last_name"
    case regDate = "reg_date"
    case avatar = "avatar"
    case backgroundAvatar = "background_avatar"
  }
}

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
  class func createFrom(dict user: [String: Any?]) -> User {
    let userUsername = user["username"] as! String
    let userEmail = user["email"] as! String
    let userFirstName = user["first_name"] as? String
    let userLastName = user["last_name"] as? String
    let userRegDate = user["reg_date"] as! Int32
    let userAvatar = user["avatar"] as? String
    let userBackgroundAvatar = user["background_avatar"] as? String

    return User(username: userUsername,
                    email: userEmail,
                    firstName: userFirstName,
                    lastName: userLastName,
                    regDate: userRegDate,
                    avatar: userAvatar,
                    backgroundAvatar: userBackgroundAvatar)
  }
}


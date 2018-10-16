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
  var firstName: String
  var lastName: String
  var regDate: Int
  var avatar: String?
  var backgroundAvatar: String?

  init(username: String,
       email: String,
       firstName: String,
       lastName: String,
       regDate: Int,
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

  convenience init(dict: [String: Any?]) {
    let userUsername = dict["username"] as! String
    let userEmail = dict["email"] as! String
    let userFirstName = dict["first_name"] as! String
    let userLastName = dict["last_name"] as! String
    let userRegDate = Int(dict["reg_date"] as! Int64) / 1000
    let userAvatar = dict["avatar"] as? String
    let userBackgroundAvatar = dict["background_avatar"] as? String

    self.init(username: userUsername,
                email: userEmail,
                firstName: userFirstName,
                lastName: userLastName,
                regDate: userRegDate,
                avatar: userAvatar,
                backgroundAvatar: userBackgroundAvatar)
  }
}


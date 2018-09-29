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

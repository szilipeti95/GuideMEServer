//
//  UserResponse.swift
//  Application
//
//  Created by Szili Péter on 2018. 09. 29..
//

import Foundation

struct UserDTO: Codable {
  var username: String
  var email: String
  var firstName: String
  var lastName: String
  var regDate: Int
  var avatar: String?
  var backgroundAvatar: String?
  var photos: [PhotoDTO]?
  var bio: String?
  var local: CityDTO?
  var next: CityDTO?
  var friendCount: Int

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

extension UserDTO {
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
}

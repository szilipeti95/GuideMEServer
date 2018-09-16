//
//  User.swift
//  CHTTPParser
//
//  Created by Szili Péter on 2018. 09. 04..
//

import Foundation
import SwiftKuery
import SwiftKueryMySQL

class User : Table {
  let tableName = "User"
  let id = Column("id", Int32.self, primaryKey: true, notNull: true)
  let username = Column("username", String.self, notNull: true)
  let password = Column("password", String.self, notNull: true)
  let salt = Column("salt", String.self, notNull: true)
  let email = Column("email", String.self, notNull: true)
  let firstName = Column("first_name", String.self, notNull: false)
  let lastLame = Column("last_name", String.self, notNull: false)
  let regDate = Column("reg_date", Int32.self, notNull: true)
  let avatar = Column("avatar", String.self, notNull: false)
  let backgroundAvatar = Column("background_avatar", String.self, notNull: false)
}

extension User {
  class func convertForSend(user: [String: Any?]) -> SendUser {
    let userUsername = user["username"] as! String
    let userEmail = user["email"] as! String
    let userFirstName = user["first_name"] as? String
    let userLastName = user["last_name"] as? String
    let userRegDate = user["reg_date"] as! Int32
    let userAvatar = user["avatar"] as? String
    let userBackgroundAvatar = user["background_avatar"] as! String

    return SendUser(username: userUsername,
                    email: userEmail,
                    firstName: userFirstName,
                    lastName: userLastName,
                    regDate: userRegDate,
                    avatar: userAvatar,
                    backgroundAvatar: userBackgroundAvatar)
  }
}

struct SendUser : Codable {
  var username: String
  var email: String
  var firstName: String?
  var lastName: String?
  var regDate: Int32
  var avatar: String?
  var backgroundAvatar: String?

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

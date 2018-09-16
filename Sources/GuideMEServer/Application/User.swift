//
//  User.swift
//  CHTTPParser
//
//  Created by Szili Péter on 2018. 09. 04..
//

import Foundation
import SwiftKuery
import SwiftKueryMySQL
import SwiftKueryORM

/*
struct User : Codable {
  static let tableName = "User"
  var id: Int
  var username: String
  var password: String
  var salt: String
  var email: String
  var fistName: String?
  var lastLame: String?
  var regDate: Int
  var avatar: String?
  var backgroundAvatar: String?

  enum CodingKeys: String, CodingKey {
    case id = "id"
    case username = "username"
    case password = "password"
    case salt = "salt"
    case email = "email"
    case fistName = "first_name"
    case lastLame = "last_name"
    case regDate = "reg_date"
    case avatar = "avatar"
    case backgroundAvatar = "background_avatar"
  }
}

extension User: Model {

}

*/
class User : Table {
  let tableName = "User"
  let id = Column("id", Int64.self, primaryKey: true, notNull: true)
  let username = Column("username", String.self, notNull: true)
  let password = Column("password", String.self, notNull: true)
  let salt = Column("salt", String.self, notNull: true)
  let email = Column("email", String.self, notNull: true)
  let firstName = Column("first_name", String.self, notNull: false)
  let lastLame = Column("last_name", String.self, notNull: false)
  let regDate = Column("reg_date", Int64.self, notNull: true)
  let avatar = Column("avatar", String.self, notNull: false)
  let backgroundAvatar = Column("background_avatar", String.self, notNull: false)
}

struct SendUser : Codable {
  var username: String
  var email: String
  var fistName: String?
  var lastLame: String?
  var regDate: Int
  var avatar: String?
  var backgroundAvatar: String?

  enum CodingKeys: String, CodingKey {
    case username = "username"
    case email = "email"
    case fistName = "first_name"
    case lastLame = "last_name"
    case regDate = "reg_date"
    case avatar = "avatar"
    case backgroundAvatar = "background_avatar"
  }
}

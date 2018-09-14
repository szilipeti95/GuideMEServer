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

struct User : Model {
  static let tableName = "User"
  var id: Int
  var username: String
  var password: String
  var salt: String
  var email: String
  var fistName: String
  var lastLame: String
  var regDate: Int
  var avatar: String
  var backgroundAvatar: String
}


/*
class User : Table {
  let tableName = "User"
  let id = Column("id", Int64.self, primaryKey: true)
  let username = Column("username", String.self)
  let password = Column("password", String.self)
  let salt = Column("salt", String.self)
  let email = Column("email", String.self)
  let fistName = Column("first_name", String.self)
  let lastLame = Column("last_name", String.self)
  let regDate = Column("reg_date", Int64.self)
  let avatar = Column("avatar", String.self)
  let backgroundAvatar = Column("background_avatar", String.self)
}
*/

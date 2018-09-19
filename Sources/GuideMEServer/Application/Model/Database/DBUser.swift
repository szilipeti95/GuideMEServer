//
//  User.swift
//  Application
//
//  Created by Szili Péter on 2018. 09. 18..
//

import Foundation
import Kitura
import SwiftKuery
import SwiftKueryMySQL

struct DBUserColumnNames {
  static let id = "id"
  static let username = "username"
  static let password = "password"
  static let salt = "salt"
  static let email = "email"
  static let firstName = "first_name"
  static let lastName = "last_name"
  static let regDate = "reg_date"
  static let avatar = "avatar"
  static let backgroundAvatar = "background_avatar"
}

class DBUser : Table {
  let tableName = "User"
  let id = Column(DBUserColumnNames.id, Int32.self, primaryKey: true, notNull: true)
  let username = Column(DBUserColumnNames.username, String.self, notNull: true)
  let password = Column(DBUserColumnNames.password, String.self, notNull: true)
  let salt = Column(DBUserColumnNames.salt, String.self, notNull: true)
  let email = Column(DBUserColumnNames.email, String.self, notNull: true)
  let firstName = Column(DBUserColumnNames.firstName, String.self, notNull: false)
  let lastName = Column(DBUserColumnNames.lastName, String.self, notNull: false)
  let regDate = Column(DBUserColumnNames.regDate, Int32.self, notNull: true)
  let avatar = Column(DBUserColumnNames.avatar, String.self, notNull: false)
  let backgroundAvatar = Column(DBUserColumnNames.backgroundAvatar, String.self, notNull: false)
}

extension DBUser {

}

struct DBUserObject {
  var id: Int32
  var username: String
  var password: String
  var salt: String
  var email: String
  var firstName: String?
  var lastName: String?
  var regDate: Int32
  var avatar: String?
  var backgroundAvatar: String?

  static func convertFrom(dict: [String: Any?]) -> DBUserObject {
    return DBUserObject(id: dict[DBUserColumnNames.id] as! Int32,
                        username: dict[DBUserColumnNames.username] as! String,
                        password: dict[DBUserColumnNames.password] as! String,
                        salt: dict[DBUserColumnNames.salt] as! String,
                        email: dict[DBUserColumnNames.email] as! String,
                        firstName: dict[DBUserColumnNames.firstName] as? String,
                        lastName: dict[DBUserColumnNames.lastName] as? String,
                        regDate: dict[DBUserColumnNames.regDate] as! Int32,
                        avatar: dict[DBUserColumnNames.avatar] as? String,
                        backgroundAvatar: dict[DBUserColumnNames.backgroundAvatar] as? String)
  }

  func foo() -> [(Column, Any)] {
    let userTable = DBUser()
    var update = [(Column, Any)]()
    if let firstName = self.firstName {
      update.append((userTable.firstName, firstName))
    }
    if let lastName = self.lastName {
      update.append((userTable.lastName, lastName))
    }

    return update
  }
}

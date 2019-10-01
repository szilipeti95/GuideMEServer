//
//  User.swift
//  Application
//
//  Created by Szili Péter on 2018. 09. 18..
//

import Foundation
import Kitura
import SwiftKuery
import SwiftKueryORM
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
  static let bio = "bio"
}

class DBUser : Table {
  let tableName = "User"
  let id = Column(DBUserColumnNames.id, Int32.self, primaryKey: true, notNull: true)
  let username = Column(DBUserColumnNames.username, String.self, notNull: true)
  let password = Column(DBUserColumnNames.password, String.self, notNull: true)
  let salt = Column(DBUserColumnNames.salt, String.self, notNull: true)
  let email = Column(DBUserColumnNames.email, String.self, notNull: true)
  let firstName = Column(DBUserColumnNames.firstName, String.self, notNull: true)
  let lastName = Column(DBUserColumnNames.lastName, String.self, notNull: true)
  let regDate = Column(DBUserColumnNames.regDate, Int64.self, notNull: true)
  let avatar = Column(DBUserColumnNames.avatar, String.self, notNull: false)
  let backgroundAvatar = Column(DBUserColumnNames.backgroundAvatar, String.self, notNull: false)
  let bio = Column(DBUserColumnNames.bio, String.self, notNull: false)
}

struct DBUserModel: Model {
  static var tableName = "User"
  static var idKeypath: IDKeyPath = \DBUserModel.id

  var id: Int?
  var username: String
  var password: String
  var salt: String
  var email: String
  var firstName: String
  var lastName: String
  var regDate: Int
  var avatar: String?
  var backgroundAvatar: String?
//  let bio: String?

  enum CodingKeys: String, CodingKey {
    case id
    case username
    case password
    case salt
    case email
    case firstName = "first_name"
    case lastName = "last_name"
    case regDate = "reg_date"
    case avatar
    case backgroundAvatar = "background_avatar"
//    case bio
  }
}

extension DBUserModel: TableFinder {
  typealias CodingEnum = CodingKeys
}

extension DBUserModel {
  private struct GetUserFilter: QueryParams {
    let email: String
  }

  private struct GetUsersWithFilter: QueryParams {
    let firstName: String
    let lastName: String

    enum CodingKeys: String, CodingKey {
      case firstName = "first_name"
      case lastName = "last_name"
    }
  }

  public static func getUserWith(email: String) -> DBUserModel? {
    let wait = DispatchSemaphore(value: 0)
    var userWithEmail: DBUserModel?

    let filter = GetUserFilter(email: email)
    DBUserModel.findAll(matching: filter) { results, error in
      guard let results = results,
        let firstResult = results.first else {
          print(error)
          wait.signal()
          return
      }

      userWithEmail = firstResult
      wait.signal()
      return
    }

    wait.wait()
    return userWithEmail
  }

  public static func getUsersWith(firstName: String, lastName: String) -> [DBUserModel]? {
    let wait = DispatchSemaphore(value: 0)
    var users: [DBUserModel]?

    let filter = GetUsersWithFilter(firstName: firstName, lastName: lastName)
    DBUserModel.findAll(matching: filter) { results, error in
      if let error = error {
        print(error)
      } else if let results = results {
        users = results
      }
      wait.signal()
      return
    }

    wait.wait()
    return users
  }

  public static func getOtherUsers(from email: String) -> [DBUserModel]? {
    let wait = DispatchSemaphore(value: 0)
    var usersNotWithEmail: [DBUserModel]?
    guard let table = try? DBUserModel.getTable(),
      let emailColumn = try? DBUserModel.getColumn(.email)  else { return nil }

    let query = Select(from: table).where(emailColumn != email)
    DBUserModel.executeQuery(query: query) { results, error in
      if let error = error {
        print(error)
      } else if let results = results {
        usersNotWithEmail = results
      }
      wait.signal()
      return
    }
    wait.wait()
    return usersNotWithEmail
  }

}

struct DBUserObject {
  var id: Int32
  var username: String
  var password: String
  var salt: String
  var email: String
  var firstName: String?
  var lastName: String?
  var regDate: Int64
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
                        regDate: (dict[DBUserColumnNames.regDate] as! Int64) / 1000,
                        avatar: dict[DBUserColumnNames.avatar] as? String,
                        backgroundAvatar: dict[DBUserColumnNames.backgroundAvatar] as? String)
  }

  func foo() -> [(Column, Any)] {
    let userTable = DBUser()
    var update = [(Column, Any)]()
    update.append((userTable.username, username))
    update.append((userTable.email, email))
    if let firstName = self.firstName {
      update.append((userTable.firstName, firstName))
    }
    if let lastName = self.lastName {
      update.append((userTable.lastName, lastName))
    }

    return update
  }
}

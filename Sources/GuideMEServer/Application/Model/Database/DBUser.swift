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
      if let error = error {
        print(error)
      } else if let results = results {
        userWithEmail = results.first
      }
      wait.signal()
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

extension DBUserModel: TableFinder {
  typealias CodingEnum = CodingKeys
}

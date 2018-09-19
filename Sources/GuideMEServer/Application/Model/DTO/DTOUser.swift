//
//  User.swift
//  CHTTPParser
//
//  Created by Szili Péter on 2018. 09. 04..
//

import Foundation
import SwiftKuery
import SwiftKueryMySQL


class SendUser : Codable {
  var username: String
  var email: String
  var firstName: String?
  var lastName: String?
  var regDate: Int
  var avatar: String?
  var backgroundAvatar: String?

  init(username: String,
       email: String,
       firstName: String?,
       lastName: String?,
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

extension SendUser {
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
  class func createFrom(dict user: [String: Any?]) -> SendUser {
    let userUsername = user["username"] as! String
    let userEmail = user["email"] as! String
    let userFirstName = user["first_name"] as? String
    let userLastName = user["last_name"] as? String
    let userRegDate = Int(user["reg_date"] as! Int32)
    let userAvatar = user["avatar"] as? String
    let userBackgroundAvatar = user["background_avatar"] as? String

    return SendUser(username: userUsername,
                    email: userEmail,
                    firstName: userFirstName,
                    lastName: userLastName,
                    regDate: userRegDate,
                    avatar: userAvatar,
                    backgroundAvatar: userBackgroundAvatar)
  }
  /*
  static func from(json: [String: Any]?) -> SendUser? {
    guard let json = json else {
      return nil
    }

    return SendUser(username: json["username"] as? String,
                    email: json["email"] as? String,
                    firstName: json["first_name"] as? String,
                    lastName: json["last_name"] as? String,
                    regDate: json["reg_date"] as? Int32,
                    avatar: json["avatar"] as? String,
                    backgroundAvatar: json["background_avatar"] as? String)
  }
 */
}

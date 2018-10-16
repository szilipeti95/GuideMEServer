//
//  DBUserPhotos.swift
//  Application
//
//  Created by Szili Péter on 2018. 09. 18..
//

import Foundation
import SwiftKuery

struct DBUserPhotosColumnNames {
  static let userphotoId = "userphoto_id"
  static let userEmail = "user_email"
  static let photoUrl = "photo_url"
  static let description = "description"
  static let likeCount = "like_count"
}

class DBUserPhotos : Table {
  let tableName = "UserPhotos"
  let id = Column(DBUserPhotosColumnNames.userphotoId, Int32.self, primaryKey: true, notNull: true)
  let userEmail = Column(DBUserPhotosColumnNames.userEmail, String.self, notNull: true)
  let photoUrl = Column(DBUserPhotosColumnNames.photoUrl, String.self, notNull: true)
  let description = Column(DBUserPhotosColumnNames.description, String.self, notNull: false)
  let likeCount = Column(DBUserPhotosColumnNames.likeCount, Int64.self, notNull: true)
}

extension DBUserPhotos {
  /*
   class func createUpdateUser(fromJson: [String: Any], with oldUser: DBUser) -> [(Column, Any)] {
   let user = DBUser()
   return [(user.username, fromJson["username"]),
   (user.password, fromJson["password"]),
   (user.email, fromJson["email"]),
   (user.firstName, fromJson["first_name"]),
   (user.lastLame, fromJson["last_name"]),
   (user.avatar, fromJson["avatar"]),
   (user.backgroundAvatar, fromJson["background_avatar"])]
   }
   */
}

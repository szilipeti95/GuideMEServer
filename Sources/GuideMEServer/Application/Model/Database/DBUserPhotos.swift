//
//  DBUserPhotos.swift
//  Application
//
//  Created by Szili Péter on 2018. 09. 18..
//

import Foundation
import SwiftKuery
import SwiftKueryORM

struct DBUserPhotosColumnNames {
  static let userphotoId = "userphoto_id"
  static let userEmail = "user_email"
  static let photoUri = "photo_uri"
  static let description = "description"
  static let likeCount = "like_count"
  static let timestamp = "timestamp"
}

class DBUserPhotos: Table {
  let tableName = "UserPhotos"
  let id = Column(DBUserPhotosColumnNames.userphotoId, Int32.self, primaryKey: true, notNull: true)
  let userEmail = Column(DBUserPhotosColumnNames.userEmail, String.self, notNull: true)
  let photoUri = Column(DBUserPhotosColumnNames.photoUri, String.self, notNull: true)
  let description = Column(DBUserPhotosColumnNames.description, String.self, notNull: false)
  let likeCount = Column(DBUserPhotosColumnNames.likeCount, Int64.self, notNull: true)
  let timestamp = Column(DBUserPhotosColumnNames.timestamp, Int64.self, notNull: true)
}

struct DBUserPhotosModel: Model {
  static var tableName = "UserPhotos"
  static var idColumnName = "userphoto_id"
  static var idColumnType = Int.self
  static var idKeypath: IDKeyPath = \DBUserPhotosModel.id

  var id: Int?
  var userEmail: String
  var photoUri: String
  var description: String?
  var likeCount: Int
  var timestamp: Int

  enum CodingKeys: String, CodingKey {
    case userEmail = "user_email"
    case photoUri = "photo_uri"
    case description
    case likeCount = "like_count"
    case timestamp
  }
}

extension DBUserPhotosModel {
  struct Filter: QueryParams {
    let user_email: String
  }

  public static func getUploadedPhotosFor(userEmail: String) -> [DBUserPhotosModel]? {
    let wait = DispatchSemaphore(value: 0)
    var photosForUser: [DBUserPhotosModel]?
    //TODO: Select(from: photosTable).where(photosTable.userEmail == email).order(by: .DESC(photosTable.timestamp))
    //    let query = Select(from: table).where("\(CodingKeys.userEmail.rawValue) = \(userEmail)")
    let filter = Filter(user_email: userEmail)
    DBUserPhotosModel.findAll(matching: filter) { results, error in
      guard let results = results else {
        wait.signal()
        return
      }

      photosForUser = results.filter { $0.photoUri.contains("image") }
      wait.signal()
      return
    }

    //    DBUserPhotosModel.executeQuery(query: query) { results, error in
    //
    //    }
    wait.wait()
    return photosForUser
  }

  public static func getUploadedPhotosCount() -> Int? {
    let wait = DispatchSemaphore(value: 0)
    var count: Int?

    DBUserPhotosModel.findAll { results, error in
      if let error = error {
        print(error)
      } else if let results = results {
        count = results.count
      }
      wait.signal()
      return
    }

    wait.wait()
    return count
  }
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

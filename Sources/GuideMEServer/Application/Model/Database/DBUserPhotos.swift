//
//  DBUserPhotos.swift
//  Application
//
//  Created by Szili Péter on 2018. 09. 18..
//

import Foundation
import SwiftKuery
import SwiftKueryORM

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
    case id = "userphoto_id"
    case userEmail = "user_email"
    case photoUri = "photo_uri"
    case description
    case likeCount = "like_count"
    case timestamp
  }
}

extension DBUserPhotosModel {
  private struct PhotoUserFilter: QueryParams {
    let user_email: String
  }

  public static func getUploadedPhotosFor(userEmail: String) -> [DBUserPhotosModel]? {
    let wait = DispatchSemaphore(value: 0)
    var photosForUser: [DBUserPhotosModel]?

    let filter = PhotoUserFilter(user_email: userEmail)
    DBUserPhotosModel.findAll(matching: filter) { results, error in
      if let error = error {
        print(error)
      }
      photosForUser = results?.filter { $0.photoUri.contains("image") }
      wait.signal()
    }
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

//
//  Photo.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 23..
//

import Foundation
import SwiftKuery
import SwiftKueryORM

struct Photo: Codable {
  var photoUri: String
  var description: String?
  var likeCount: Int
  var timestamp: Int

  init(photoUri: String, description: String?, likeCount: Int, timestamp: Int) {
    self.photoUri = photoUri
    self.description = description
    self.likeCount = likeCount
    self.timestamp = timestamp
  }

  init(dict: [String: Any?]) {
    let photoUri = dict["photo_uri"] as! String
    let description = dict["description"] as? String
    let likeCount = Int(dict["like_count"] as! Int64)
    let timestamp = Int(dict["timestamp"] as! Int64)

    self.init(photoUri: photoUri,
              description: description,
              likeCount: likeCount,
              timestamp: timestamp)
  }

  enum CodingKeys: String, CodingKey {
    case photoUri = "photo_uri"
    case description
    case likeCount = "like_count"
    case timestamp
  }
}

extension Photo: Model {
  public static func getUploadedPhotosFor(userEmail: String) -> [Photo]? {
    let wait = DispatchSemaphore(value: 0)
    guard let table: Table = try? Photo.getTable() else { return nil }

    var photosForUser: [Photo]?
    //TODO: Select(from: photosTable).where(photosTable.userEmail == email).order(by: .DESC(photosTable.timestamp))
    let query = Select(from: table).where("user_email == \(userEmail)")

    Photo.executeQuery(query: query) { results, error in
      guard let results = results else { return }


      photosForUser = results.filter { $0.photoUri.contains("image") }
      wait.signal()
      return
    }
    wait.wait()
    return photosForUser
  }

}

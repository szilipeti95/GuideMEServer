//
//  Photo.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 23..
//

import Foundation
import SwiftKueryORM

struct PhotoDTO: Codable {
  var photoUri: String
  var description: String?
  var likeCount: Int
  var timestamp: Int

  enum CodingKeys: String, CodingKey {
    case photoUri = "photo_uri"
    case description
    case likeCount = "like_count"
    case timestamp
  }
}

extension PhotoDTO {
  init(dbPhoto: DBUserPhotosModel) {
    self.photoUri = dbPhoto.photoUri
    self.description = dbPhoto.description
    self.likeCount = dbPhoto.likeCount
    self.timestamp = dbPhoto.timestamp
  }
}

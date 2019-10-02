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

  enum CodingKeys: String, CodingKey {
    case photoUri = "photo_uri"
    case description
    case likeCount = "like_count"
    case timestamp
  }
}

extension Photo {
  init(photo: DBUserPhotosModel) {
    self.photoUri = photo.photoUri
    self.description = photo.description
    self.likeCount = photo.likeCount
    self.timestamp = photo.timestamp
  }
}

//
//  UserInfo.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 20..
//

import Foundation

class UserInfo : Codable {
  var photoUrl: String

  init(photoUrl: String) {
    self.photoUrl = photoUrl
  }

  convenience init(dict: [String: Any?]) {
    let photoUrl = dict[DBUserPhotosColumnNames.photoUrl] as! String
    self.init(photoUrl: photoUrl)
  }

  enum CodingKeys: String, CodingKey {
    case photoUrl
  }
}

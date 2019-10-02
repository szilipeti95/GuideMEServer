//
//  City.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 21..
//

import Foundation

struct City: Codable {
  var city: String
  var country: String
  var imageUri: String

  enum CodingKeys: String, CodingKey {
    case city
    case country
    case imageUri = "image_uri"
  }
}

extension City {
  init(dbCity: DBCitiesModel) {
    self.city = dbCity.city
    self.country = dbCity.country
    self.imageUri = dbCity.imageUri
  }

  init(dict: [String: Any?]) {
    let city = dict[DBCitiesColumnNames.city] as! String
    let country = dict[DBCitiesColumnNames.country] as! String
    let imageUri = dict[DBCitiesColumnNames.imageUri] as! String

    self.init(city: city,
              country: country,
              imageUri: imageUri)
  }
}

//
//  City.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 21..
//

import Foundation

class City: Codable {
  var city: String
  var country: String
  var imageUri: String

  init(city: String, country: String, imageUri: String) {
    self.city = city
    self.country = country
    self.imageUri = imageUri
  }

  init(dbCity: DBCitiesModel) {
    self.city = dbCity.city
    self.country = dbCity.country
    self.imageUri = dbCity.imageUri
  }

  convenience init(dict: [String: Any?]) {
    let city = dict[DBCitiesColumnNames.city] as! String
    let country = dict[DBCitiesColumnNames.country] as! String
    let imageUri = dict[DBCitiesColumnNames.imageUri] as! String

    self.init(city: city,
              country: country,
              imageUri: imageUri)
  }

  enum CodingKeys: String, CodingKey {
    case city
    case country
    case imageUri = "image_uri"
  }
}

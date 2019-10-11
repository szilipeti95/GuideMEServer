//
//  City.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 21..
//

import Foundation

struct CityDTO: Codable {
  var city: String
  var country: String
  var imageUri: String

  enum CodingKeys: String, CodingKey {
    case city
    case country
    case imageUri = "image_uri"
  }
}

extension CityDTO {
  init(dbCity: DBCitiesModel) {
    self.city = dbCity.city
    self.country = dbCity.country
    self.imageUri = dbCity.imageUri
  }
}

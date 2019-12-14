//
//  Guide.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 21..
//

import Foundation

struct GuideDTO: Codable {
  var city: CityDTO
  var type: Int
  var from: Int?
  var to: Int?
  var preferenceType: [Int]

  enum CodingKeys: String, CodingKey {
    case city
    case type
    case from
    case to
    case preferenceType = "preference_type"
  }
}

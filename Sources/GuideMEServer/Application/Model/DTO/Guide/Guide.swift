//
//  Guide.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 21..
//

import Foundation

struct Guide: Codable {
  var city: City
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

extension Guide {
  init(dbGuide: DBGuidesModel, dbCity: DBCitiesModel, prefTypes: [DBGuidePreferencesModel]) {
    self.city = City(dbCity: dbCity)
    self.type = dbGuide.type
    if let from = dbGuide.from, let to = dbGuide.to {
      self.from = from / 1000
      self.to = to / 1000
    }
    self.preferenceType = prefTypes.map({ $0.prefTypeId })
  }
}

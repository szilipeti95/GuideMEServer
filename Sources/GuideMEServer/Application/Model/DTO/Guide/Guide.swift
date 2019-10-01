//
//  Guide.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 21..
//

import Foundation

class Guide: Codable {
  var city: City
  var type: Int
  var from: Int?
  var to: Int?
  var preferenceType: [Int]

  init(dbGuide: DBGuidesModel, dbCity: DBCitiesModel, prefTypes: [DBGuidePreferencesModel]) {
    self.city = City(dbCity: dbCity)
    self.type = dbGuide.type
    self.from = dbGuide.from
    self.to = dbGuide.to
    self.preferenceType = prefTypes.map({ $0.prefTypeId })
  }


  init(city: City, type: Int, from: Int?, to: Int?, preferenceType: [Int]) {
    self.city = city
    self.type = type
    self.from = from
    self.to = to
    self.preferenceType = preferenceType
  }

  convenience init(dict: [String: Any?]) {
    let type = Int(dict["type"] as! Int)
    var from: Int? = nil
    var to: Int? = nil
    if dict["from"] as? Int != nil {
      from = Int(dict["from"] as! Int)
    }
    if dict["to"] as? Int != nil {
      to = Int(dict["to"] as! Int)
    }
    let city = City(dict: dict["city"] as! [String: Any?])
    let preferenceType = dict["preference_type"] as! [Int]
    self.init(city: city,
              type: type,
              from: from,
              to: to,
              preferenceType: preferenceType)

  }

  convenience init(dict: [String: Any?], city: City, preferenceType: [Int]) {
    let type = Int(dict["type"] as! Int32)
    var from: Int? = nil
    var to: Int? = nil
    if dict["from"] as? Int64 != nil {
      from = Int(dict["from"] as! Int64) / 1000
    }
    if dict["to"] as? Int64 != nil {
      to = Int(dict["to"] as! Int64) / 1000
    }
    self.init(city: city,
              type: type,
              from: from,
              to: to,
              preferenceType: preferenceType)
    
  }
  enum CodingKeys: String, CodingKey {
    case city
    case type
    case from
    case to
    case preferenceType = "preference_type"
  }
}

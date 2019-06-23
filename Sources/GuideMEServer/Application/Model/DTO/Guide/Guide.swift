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

  init(city: City, type: Int, from: Int?, to: Int?, preferenceType: [Int]) {
    self.city = city
    self.type = type
    self.from = from
    self.to = to
    self.preferenceType = preferenceType
  }

  convenience init(dict: [String: Any?]) {
    print("Decoding type")
    print("\(dict["type"])")
    let type = Int(dict["type"] as! Int)
    var from: Int? = nil
    var to: Int? = nil
    print("Decoding from")
    print("\(dict["from"])")
    if dict["from"] as? Int64 != nil {
      from = Int(dict["from"] as! Int64)
    }
    print("Decoding to")
    print("\(dict["to"])")
    if dict["to"] as? Int64 != nil {
      to = Int(dict["to"] as! Int64)
    }
    print("Decoding city")
    print("\(dict["city"])")
    let city = City(dict: dict["city"] as! [String: Any?])
    print("Decoding preference_type")
    print("\(dict["preference_type"])")
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

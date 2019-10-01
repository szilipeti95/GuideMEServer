//
//  DBCities.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 21..
//

import Foundation
import SwiftKuery
import SwiftKueryORM
import SwiftKueryMySQL

struct DBCitiesColumnNames {
  static let citiesId = "cities_id"
  static let city = "city"
  static let country = "country"
  static let imageUri = "image_uri"
}

class DBCities: Table {
  let tableName = "Cities"
  let citiesId = Column(DBCitiesColumnNames.citiesId, Int32.self, primaryKey: true, notNull: true)
  let city = Column(DBCitiesColumnNames.city, String.self, notNull: true)
  let country = Column(DBCitiesColumnNames.country, String.self, notNull: true)
  let imageUri = Column(DBCitiesColumnNames.imageUri, String.self, notNull: true)
}

struct DBCitiesModel: Model {
  static var tableName = "Cities"

  var citiesId: Int
  var city: String
  var country: String
  var imageUri: String

  enum CodingKeys: String, CodingKey {
    case citiesId = "cities_id"
    case city
    case country
    case imageUri = "image_uri"
  }
}

extension DBCitiesModel {
  private struct Filter: QueryParams {
    let cities_id: Int
  }

  public static func getCity(with cityId: Int) -> DBCitiesModel? {
    let wait = DispatchSemaphore(value: 0)
    var cityWithId: DBCitiesModel?

    let filter = Filter(cities_id: cityId)
    DBCitiesModel.findAll(matching: filter) { results, error in
      guard let results = results,
        let firstResult = results.first else {
          print(error)
          wait.signal()
          return
      }
      cityWithId = firstResult
      wait.signal()
      return
    }

    wait.wait()
    return cityWithId
  }
}

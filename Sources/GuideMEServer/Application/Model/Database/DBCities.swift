//
//  DBCities.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 21..
//

import Foundation
import SwiftKuery
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

extension DBConversation {

}

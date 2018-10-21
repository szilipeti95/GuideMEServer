//
//  DBGuides.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 21..
//

import Foundation
import SwiftKuery
import SwiftKueryMySQL

struct DBGuidesColumnNames {
  static let guideId = "guide_id"
  static let userEmail = "user_email"
  static let cityId = "city_id"
  static let type = "type"
  static let from = "from"
  static let to = "to"
}

class DBGuides: Table {
  let tableName = "Guides"
  let guideId = Column(DBGuidesColumnNames.guideId, Int32.self, primaryKey: true, notNull: true)
  let userEmail = Column(DBGuidesColumnNames.userEmail, String.self, notNull: true)
  let cityId = Column(DBGuidesColumnNames.cityId, Int32.self, notNull: true)
  let type = Column(DBGuidesColumnNames.type, Int32.self, notNull: false)
  let from = Column(DBGuidesColumnNames.from, Int64.self, notNull: false)
  let to = Column(DBGuidesColumnNames.to, Int64.self, notNull: true)
}

extension DBGuides {

}

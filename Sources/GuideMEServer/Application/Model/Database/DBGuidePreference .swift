//
//  GuidePreferences.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 21..
//

import Foundation
import SwiftKuery
import SwiftKueryMySQL

struct DBGuidePreferencesColumnNames {
  static let id = "id"
  static let guideId = "guide_id"
  static let prefTypeId = "prefType_id"
}

class DBGuidePreferences: Table {
  let tableName = "GuidePreferences"
  let id = Column(DBGuidePreferencesColumnNames.id, Int32.self, primaryKey: true, notNull: true)
  let guideId = Column(DBGuidePreferencesColumnNames.guideId, Int32.self, notNull: true)
  let prefTypeId = Column(DBGuidePreferencesColumnNames.prefTypeId, Int32.self, notNull: true)
}

extension DBGuidePreferences {

}

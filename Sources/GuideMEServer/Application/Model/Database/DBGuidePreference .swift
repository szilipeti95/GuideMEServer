//
//  GuidePreferences.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 21..
//

import Foundation
import SwiftKuery
import SwiftKueryORM
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

struct DBGuidePreferencesModel: Model {
  static var tableName = "GuidePreferences"
  static var idKeypath: IDKeyPath = \DBGuidePreferencesModel.id

  var id: Int?
  var guideId: Int
  var prefTypeId: Int

  enum CodingKeys: String, CodingKey {
    case id
    case guideId = "guide_id"
    case prefTypeId = "prefType_id"
  }
}

extension DBGuidePreferencesModel {
  private struct PreferencesWithGuideIdFilter: QueryParams {
    let guideId: Int

    enum CodingKeys: String, CodingKey {
      case guideId = "guide_id"
    }
  }

  public static func getPreferences(guideId: Int?) -> [DBGuidePreferencesModel]? {
    guard let guideId = guideId else { return nil }
    let wait = DispatchSemaphore(value: 0)
    var preferencesWithGuideId: [DBGuidePreferencesModel]?

    let filter = PreferencesWithGuideIdFilter(guideId: guideId)
    DBGuidePreferencesModel.findAll(matching: filter) { results, error in
      if let error = error {
        print(error)
      } else if let results = results {
        preferencesWithGuideId = results
      }
      wait.signal()
    }
    wait.wait()
    return preferencesWithGuideId
  }

  public static func deleteAll(guideId: Int) -> RequestError? {
    let wait = DispatchSemaphore(value: 0)
    var result: RequestError?

    let filter = PreferencesWithGuideIdFilter(guideId: guideId)
    DBGuidePreferencesModel.deleteAll(matching: filter) { error in
      result = error
      wait.signal()
    }
    wait.wait()
    return result
  }
}

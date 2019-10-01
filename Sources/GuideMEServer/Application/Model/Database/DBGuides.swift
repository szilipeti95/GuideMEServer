//
//  DBGuides.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 21..
//

import Foundation
import SwiftKuery
import SwiftKueryORM
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

struct DBGuidesModel: Model {
  static var tableName = "Guides"

  let userEmail: String
  let cityId: Int
  let type: Int?
  let from: Int?
  let to: Int?

  enum CodingKeys: String, CodingKey {
    case userEmail = "user_email"
    case cityId = "city_id"
    case type = "type"
    case from = "from"
    case to = "to"
  }
}

extension DBGuidesModel {
  private struct Filter: QueryParams {
    let user_email: String
    let type: Int
  }

  public static func getLocalGuide(for userEmail: String) -> DBGuidesModel? {
    let wait = DispatchSemaphore(value: 0)
    var localGuideForUserEmail: DBGuidesModel?

    let filter = Filter(user_email: userEmail, type: 0)
    DBGuidesModel.findAll(matching: filter) { results, error in
      guard let results = results,
        let firstResult = results.first else {
        print(error)
        wait.signal()
        return
      }
      localGuideForUserEmail = firstResult
      wait.signal()
      return
    }

    wait.wait()
    return localGuideForUserEmail
  }

  public static func getNextGuide(for userEmail: String) -> DBGuidesModel? {
    let wait = DispatchSemaphore(value: 0)
    var localGuideForUserEmail: DBGuidesModel?

    let filter = Filter(user_email: userEmail, type: 1)
    DBGuidesModel.findAll(matching: filter) { results, error in
      guard let results = results?.sorted(by: { $0.from ?? 0 < $1.from ?? 0 }),
        let firstResult = results.first else {
          print(error)
          wait.signal()
          return
      }
      localGuideForUserEmail = firstResult
      wait.signal()
      return
    }

    wait.wait()
    return localGuideForUserEmail
  }
}

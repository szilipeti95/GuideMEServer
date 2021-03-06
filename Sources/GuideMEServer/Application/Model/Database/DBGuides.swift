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

struct DBGuidesModel: Model {
  static var tableName = "Guides"
  static var idColumnName = "guide_id"
  static var idKeypath: IDKeyPath = \DBGuidesModel.guideId

  var guideId: Int?
  var userEmail: String
  var cityId: Int
  var type: Int
  var from: Int?
  var to: Int?

  enum CodingKeys: String, CodingKey {
    case guideId = "guide_id"
    case userEmail = "user_email"
    case cityId = "city_id"
    case type = "type"
    case from = "from"
    case to = "to"
  }
}

extension DBGuidesModel {
  private struct GuideFilter: QueryParams {
    let email: String
    let type: Int

    enum CodingKeys: String, CodingKey {
      case email = "user_email"
      case type
    }
  }

  public static func getLocalGuide(for userEmail: String) -> DBGuidesModel? {
    let wait = DispatchSemaphore(value: 0)
    var localGuideForUserEmail: DBGuidesModel?

    let filter = GuideFilter(email: userEmail, type: 0)
    DBGuidesModel.findAll(matching: filter) { results, error in
      if let error = error {
        print(error)
      }
      localGuideForUserEmail = results?.first
      wait.signal()
      return
    }

    wait.wait()
    return localGuideForUserEmail
  }

  public static func getNextGuide(for userEmail: String) -> DBGuidesModel? {
    let wait = DispatchSemaphore(value: 0)
    var localGuideForUserEmail: DBGuidesModel?

    let filter = GuideFilter(email: userEmail, type: 1)
    DBGuidesModel.findAll(matching: filter) { results, error in
      if let error = error {
        print(error)
      }
      localGuideForUserEmail = results?.sorted(by: {$0.from ?? 0 < $1.from ?? 1}).first
      wait.signal()
      return
    }

    wait.wait()
    return localGuideForUserEmail
  }

  private struct GetGuidesFilter: QueryParams {
    let email: String
    let cityId: Int?

    enum CodingKeys: String, CodingKey {
      case email = "user_email"
      case cityId = "city_id"
    }
  }

  public static func getGuides(for userEmail: String, cityId: Int? = nil) -> [DBGuidesModel]? {
    let wait = DispatchSemaphore(value: 0)
    var guides: [DBGuidesModel]?

    let filter = GetGuidesFilter(email: userEmail, cityId: cityId)
    DBGuidesModel.findAll(matching: filter) { results, error in
      if let error = error {
        print(error)
      } else if let results = results {
        guides = results
      }
      wait.signal()
    }

    wait.wait()
    return guides
  }
}

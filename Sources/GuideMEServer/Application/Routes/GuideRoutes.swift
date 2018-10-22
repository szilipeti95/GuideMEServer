//
//  GuideRoutes.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 21..
//

import Foundation
import Kitura
import SwiftKuery
import SwiftKueryMySQL

func addGuideRoutes(app: Backend) {
  app.router.get("/guides/:email", allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.get("/guides/:email", handler: app.getGuides)

  app.router.get("/cities", allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.get("/cities", handler: app.getCities)
  /*
  app.router.post("/image", middleware: BodyParser())
 */

  app.router.post("/guide", middleware: BodyParser())
  app.router.post("/guide", allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.post("/guide", handler: app.postGuide)
}

extension Backend {
  fileprivate func getGuides(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard request.authorizedUser != nil else {
      response.send("").status(.unauthorized); next()
      return
    }
    guard let email = request.parameters["email"] else {
      response.send("").status(.badRequest); next()
      return
    }
    let guideTable = DBGuides()
    let preferencesTable = DBGuidePreferences()
    let cityTable = DBCities()
    let selectGuideQuery = Select(from: guideTable).where(guideTable.userEmail == email)

    if let connection = pool.getConnection() {
      connection.execute(query: selectGuideQuery) { selectGuideResult in
        guard let guideResultRows = selectGuideResult.asRows else {
          response.send("").status(.internalServerError)
          return
        }
        var guides = [Guide]()
        for guideResultRow in guideResultRows {
          let cityId = Int(guideResultRow["city_id"] as! Int32)
          let guideId = Int(guideResultRow["guide_id"] as! Int32)
          let selectCity = Select(from: cityTable).where(cityTable.citiesId == cityId)
          let selectPreference = Select(from: preferencesTable).where(preferencesTable.guideId == guideId)
          connection.execute(query: selectCity) { selectCityResult in
            guard let selectCityRow = selectCityResult.asRows?[0] else {
              response.send("").status(.internalServerError); next()
              return
            }
            let city = City(dict: selectCityRow)
            connection.execute(query: selectPreference) { selectPreferenceResult in
              guard let selectPreferenceRows = selectPreferenceResult.asRows else {
                response.send("").status(.internalServerError); next()
                return
              }
              var prefs = [Int]()
              for selectPreferenceRow in selectPreferenceRows {
                prefs.append(Int(selectPreferenceRow["prefType_id"] as! Int32))
              }
              let guide = Guide(dict: guideResultRow, city: city, preferenceType: prefs)
              guides.append(guide)
            }
          }
        }
        guard let data = try? JSONEncoder().encode(guides) else {
          response.send("").status(.internalServerError)
          return
        }
        let jsonString = String(data: data, encoding: .utf8)!
        response.send(jsonString); next()
      }
    }
  }

  fileprivate func getCities(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    let citiesTable = DBCities()
    let selectQuery = Select(from: citiesTable)
    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        guard let rows = selectResult.asRows else {
          response.send("").status(.internalServerError); next()
          return
        }
        var cities = [City]()
        for row in rows {
          let city = City(dict: row)
          cities.append(city)
        }

        guard let data = try? JSONEncoder().encode(cities) else {
          response.send("").status(.internalServerError)
          return
        }
        let jsonString = String(data: data, encoding: .utf8)!
        response.send(jsonString); next()
      }
    }
  }

  fileprivate func postGuide(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser,
      let data = request.body?.asJSON else {
      response.send("").status(.unauthorized); next()
      return
    }

    let guide = Guide(dict: data)

    let guidesTable = DBGuides()

    let cityTable = DBCities()
    let selectQuery = Select(from: cityTable).where(cityTable.city == guide.city.city && cityTable.country == guide.city.country)
    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { cityResult in
        print(cityResult)
        guard let rows = cityResult.asRows else {
          response.send("").status(.badRequest); next()
          return
        }
        if rows.count == 0 {
          response.send("").status(.badRequest); next()
          return
        }
        guard let cityId = rows[0]["cities_id"] as? Int32 else {
          response.send("").status(.internalServerError); next()
          return
        }
        var valueTuples: [(Column, Any)] = [(guidesTable.userEmail, email),
                                            (guidesTable.cityId, cityId),
                                            (guidesTable.type, guide.type)]
        if guide.type == 1 {
          guard let from = guide.from, let to = guide.to else {
            response.send("").status(.badRequest); next()
            return
          }
          valueTuples.append((guidesTable.from, from))
          valueTuples.append((guidesTable.to, to))
        }
        let insertQuery = Insert(into: guidesTable, valueTuples: valueTuples, returnID: true)
        connection.execute(query: insertQuery) { guideInsertResult in
          guard let id = guideInsertResult.asRows?[0]["id"] else {
            return
          }
          for pref in guide.preferenceType {
            let prefTable = DBGuidePreferences()
            if let id = id {
              let insertPrefQuery = Insert(into: prefTable, valueTuples: [(prefTable.guideId, id), (prefTable.prefTypeId, pref)])
              connection.execute(query: insertPrefQuery) { result in
                print(result)
              }
            }
          }
          response.send(""); next();
        }
      }
    }

  }
}

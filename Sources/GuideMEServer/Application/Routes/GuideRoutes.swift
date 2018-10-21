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


  /*
  fileprivate func uploadImage(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let parts = request.body?.asMultiPart,
      let email = request.authorizedUser else {
        return
    }
    let imagePart = parts.filter { $0.type.contains("image") }.first
    let descriptionPart = parts.filter { $0.name == "description" }.first
    let userPhotosTable = DBUserPhotos()
    let selectQuery = Select(from: userPhotosTable)
    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
 */
}

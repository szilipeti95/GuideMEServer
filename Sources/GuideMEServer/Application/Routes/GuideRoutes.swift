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

  app.router.put("/guide", middleware: BodyParser())
  app.router.put("/guide", allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.put("/guide", handler: app.putGuide)

  app.router.delete("/guide", middleware: BodyParser())
  app.router.delete("/guide", allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.delete("/guide", handler: app.deleteGuide)
}

extension Backend {

  fileprivate func newGetGuides(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
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
    let selectGuideQuery = Select(from: guideTable).leftJoin(preferencesTable).on(guideTable.guideId == preferencesTable.guideId).where(guideTable.userEmail == email)

    if let connection = pool.getConnection() {
      connection.execute(query: selectGuideQuery) { selectGuideResult in

        guard let guideResultRows = selectGuideResult.asRows else {
          response.send("").status(.internalServerError)
          return
        }
        var guides = [Guide]()

        let mappedDicts = self.map(dicts: guideResultRows, key: "city_id", columns: [DBGuidePreferencesColumnNames.prefTypeId])
        for dict in mappedDicts {
          let guide = Guide(dict: dict)
          guides.append(guide)
        }
        guides = guides.sorted(by: { $0.from ?? 0 < $1.from ?? 1 })
        guard let data = try? JSONEncoder().encode(guides) else {
          response.send("").status(.internalServerError)
          return
        }
        let jsonString = String(data: data, encoding: .utf8)!
        response.send(jsonString); next()
      }
    }
  }

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
        guides = guides.sorted(by: { $0.from ?? 0 < $1.from ?? 1 })
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
    print("Incoming postGuide request from: \(email)")

    let guide = Guide(dict: data)

    let guidesTable = DBGuides()

    let cityTable = DBCities()
    let selectQuery = Select(from: cityTable).where(cityTable.city == guide.city.city && cityTable.country == guide.city.country)
    print("Performing connection...")
    if let connection = pool.getConnection() {
      print("Performing selectQuery...")
      connection.execute(query: selectQuery) { cityResult in
        print("selectResult: \(cityResult)")
        guard let rows = cityResult.asRows else {
          response.send("").status(.badRequest); next()
          return
        }
        print("checking row count")
        if rows.count == 0 {
          response.send("").status(.badRequest); next()
          return
        }
        print("casting cityId")
        guard let cityId = rows[0]["cities_id"] as? Int32 else {
          response.send("").status(.internalServerError); next()
          return
        }
        var valueTuples: [(Column, Any)] = [(guidesTable.userEmail, email),
                                            (guidesTable.cityId, cityId),
                                            (guidesTable.type, Int32(guide.type))]
        print("cheking guide type")
        if guide.type == 1 {
          guard let from = guide.from, let to = guide.to else {
            response.send("").status(.badRequest); next()
            return
          }
          valueTuples.append((guidesTable.from, Int64(from*1000)))
          valueTuples.append((guidesTable.to, Int64(to*1000)))
        }
        print("creating insert query")
        let insertQuery = Insert(into: guidesTable, valueTuples: valueTuples, returnID: true)
        print("executing insert query")
        connection.execute(query: insertQuery) { guideInsertResult in
          print("getting inserted id")
          guard let id = guideInsertResult.asRows?[0]["id"] else {
            return
          }
          print("inserting preferences")
          for pref in guide.preferenceType {
            let prefTable = DBGuidePreferences()
            if let id = id {
              let insertPrefQuery = Insert(into: prefTable, valueTuples: [(prefTable.guideId, id), (prefTable.prefTypeId, pref)])
              print("performing insert to preferences")
              connection.execute(query: insertPrefQuery) { result in
                print("insert is successful")
//                print(result)
              }
            }
          }
          print("request success")
          response.send(""); next();
        }
      }
    }
  }

  fileprivate func putGuide(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser,
      let data = request.body?.asJSON else {
        response.send("").status(.unauthorized); next()
        return
    }

    let guide = Guide(dict: data)
    let guideTable = DBGuides()

    let cityTable = DBCities()
    let selectCityQuery = Select(from: cityTable).where(cityTable.city == guide.city.city && cityTable.country == guide.city.country)
    if let connection = pool.getConnection() {
      connection.execute(query: selectCityQuery) { selectCityResult in
        guard let rows = selectCityResult.asRows else {
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

        let selectGuideQuery = Select(from: guideTable).where(guideTable.userEmail == email && guideTable.cityId == Int(cityId))
        connection.execute(query: selectGuideQuery) { selectGuideResult in
          guard let rows = selectGuideResult.asRows else {
            response.send("").status(.badRequest); next()
            return
          }
          if rows.count == 0 {
            response.send("").status(.badRequest); next()
            return
          }
          guard let guideId = rows[0]["guide_id"] as? Int32 else {
            response.send("").status(.internalServerError); next()
            return
          }
          let prefsTable = DBGuidePreferences()
          let deletePrefs = Delete(from: prefsTable).where(prefsTable.guideId == Int(guideId))
          connection.execute(query: deletePrefs) {_ in

          }
          for pref in guide.preferenceType {
            let values: [(Column, Any)] = [(prefsTable.guideId, guideId),
                                           (prefsTable.prefTypeId, pref)]
            let insertPref = Insert(into: prefsTable, valueTuples: values)
            connection.execute(query: insertPref) { _ in

            }
          }
          guard let from = guide.from,
            let to = guide.to else {
              response.send("").status(.OK); next()
              return
          }

          let updateQuery = Update(guideTable, set: [(guideTable.from, from * 1000),
                                                     (guideTable.to, to * 1000)]).where(guideTable.guideId == Int(guideId))
          connection.execute(query: updateQuery) { _ in
            response.send("").status(.OK); next()
          }
        }
      }
    }
  }

  fileprivate func deleteGuide(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser,
      let data = request.body?.asJSON else {
        response.send("").status(.unauthorized); next()
        return
    }

    let city = City(dict: data)

    let cityTable = DBCities()
    let selectCityQuery = Select(from: cityTable).where(cityTable.city == city.city && cityTable.country == city.country)
    if let connection = pool.getConnection() {
      connection.execute(query: selectCityQuery) { selectCityResult in
        guard let rows = selectCityResult.asRows else {
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
        let guideTable = DBGuides()
        let deleteGuideQuery = Delete(from: guideTable).where(guideTable.userEmail == email && guideTable.cityId == Int(cityId))
        connection.execute(query: deleteGuideQuery) { deleteGuideResult in
          if deleteGuideResult.success {
            response.send("").status(.OK); next()
          } else {
            response.send("").status(.internalServerError); next()
          }
        }
      }
    }
  }
}

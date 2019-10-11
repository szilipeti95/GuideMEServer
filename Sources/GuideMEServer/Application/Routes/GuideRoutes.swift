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
  app.router.get(Paths.guidesEmail, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.get(Paths.guidesEmail, handler: app.getGuides)

  app.router.get(Paths.cities, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.get(Paths.cities, handler: app.getCities)

  app.router.post(Paths.guide, middleware: BodyParser())
  app.router.post(Paths.guide, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.post(Paths.guide, handler: app.postGuide)

  app.router.put(Paths.guide, middleware: BodyParser())
  app.router.put(Paths.guide, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.put(Paths.guide, handler: app.putGuide)

  app.router.delete(Paths.guide, middleware: BodyParser())
  app.router.delete(Paths.guide, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.delete(Paths.guide, handler: app.deleteGuide)
}

extension Backend {
  fileprivate func getGuides(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard request.authorizedUser != nil else { return }
    guard let email = request.parameters["email"] else {
      try response.send(status: .badRequest).end(); next()
      return
    }

    if let dbGuides = DBGuidesModel.getGuides(for: email) {
      var guides: [GuideDTO] = []
      for guide in dbGuides {
        let dbGuidePrefs = DBGuidePreferencesModel.getPreferences(guideId: guide.guideId) ?? []
        if let dbCity = DBCitiesModel.getCity(with: guide.cityId) {
          guides.append(GuideDTO(dbGuide: guide, dbCity: dbCity, prefTypes: dbGuidePrefs))
        } else {
          try response.send(status: .internalServerError).end(); next()
          return
        }
      }
      guides.sort(by: { first, second in first.from ?? 0 < second.to ?? 1 })
      try response.send(json: guides).end(); next()
    } else {
      try response.send(status: .internalServerError).end(); next()
    }
  }

  fileprivate func getCities(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let dbCities = DBCitiesModel.getCities() else {
      try response.send(status: .internalServerError).end(); next()
      return
    }
    let cities = dbCities.map({ CityDTO(dbCity: $0) })
    try response.send(json: cities).end(); next()
  }


  fileprivate func postGuide(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser,
      let guide: GuideDTO = request.body?.asObject() else {
      response.send("").status(.unauthorized); next()
      return
    }

    if let dbCity = DBCitiesModel.getCity(city: guide.city.city, country: guide.city.country) {
      var dbGuide = DBGuidesModel(guideId: nil,
                                  userEmail: email,
                                  cityId: dbCity.citiesId,
                                  type: guide.type,
                                  from: nil, to: nil)
      if dbGuide.type == 1 {
        guard let from = guide.from, let to = guide.to else {
          try response.send(status: .badRequest).end(); next()
          return
        }
        dbGuide.from = from*1000
        dbGuide.to = to*1000
      }

      dbGuide.save { (guideId: Int?, result: DBGuidesModel?, error: RequestError?) in
        if let guideId = guideId {
          for prefType in guide.preferenceType {
            let dbPrefType = DBGuidePreferencesModel(id: nil, guideId: guideId, prefTypeId: prefType)
            dbPrefType.save { result, error in }
          }
          try? response.send(status: .OK).end(); next()
        } else {
          try? response.send(status: .internalServerError).end(); next()
        }
      }
    } else {
      try response.send(status: .internalServerError).end(); next()
    }
  }

  fileprivate func putGuide(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser,
      let guide: GuideDTO = request.body?.asObject() else {
        response.send("").status(.unauthorized); next()
        return
    }

    if let dbCity = DBCitiesModel.getCity(city: guide.city.city, country: guide.city.country),
      let dbGuide = DBGuidesModel.getGuides(for: email, cityId: dbCity.citiesId)?.first,
      let dbGuideId = dbGuide.guideId {
      var updatedGuide = DBGuidesModel(guideId: dbGuideId,
                                       userEmail: email,
                                       cityId: dbCity.citiesId,
                                       type: dbGuide.type, from: dbGuide.from, to: dbGuide.to)
      if let from = guide.from, let to = guide.to { updatedGuide.from = from * 1000; updatedGuide.to = to * 1000 }
      updatedGuide.update(id: dbGuideId) { result, error in
        guard error == nil,
              DBGuidePreferencesModel.deleteAll(guideId: dbGuideId) == nil else {
          try? response.send(status: .internalServerError).end(); next()
          return
        }
        for prefType in guide.preferenceType {
          let dbPrefType = DBGuidePreferencesModel(id: nil, guideId: dbGuideId, prefTypeId: prefType)
          dbPrefType.save { result, error in }
        }
        try? response.send(status: .OK).end(); next()
      }
    } else {
      try response.send(status: .internalServerError).end(); next()
    }
  }

  fileprivate func deleteGuide(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser,
      let city: CityDTO = request.body?.asObject() else {
        response.send("").status(.unauthorized); next()
        return
    }

    if let dbCity = DBCitiesModel.getCity(city: city.city, country: city.country),
      let dbGuideId = DBGuidesModel.getGuides(for: email, cityId: dbCity.citiesId)?.first?.guideId {
      DBGuidesModel.delete(id: dbGuideId) { error in
        if let error = error {
          print(error)
          try? response.send(status: .internalServerError).end(); next()
        } else  {
          try? response.send(status: .OK).end(); next()
        }
      }
    } else {
      try response.send(status: .internalServerError).end(); next()
    }
  }
}

//
//  AdminRoutes.swift
//  Application
//
//  Created by Szili Péter on 2018. 09. 16..
//

import Foundation
import Kitura

func addAdminRoutes(app: Backend) {
  app.adminRouter.get("/shutdown") {
    request, response, next in
    response.send("Stopping server!")
    Kitura.stop()
  }
}

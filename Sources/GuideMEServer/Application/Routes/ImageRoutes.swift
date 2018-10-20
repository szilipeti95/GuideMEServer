//
//  ImageRoutes.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 15..
//

import Foundation
import Kitura
import SwiftKuery

func addImagesRoutes(app: Backend) {
  app.router.post("/image", middleware: BodyParser())
  app.router.post("/image", allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.post("/image", handler: app.uploadImage)


  app.router.get("/image", allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.get("/image", handler: app.downloadImage)
}

extension Backend {
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
        guard let count = selectResult.asRows?.count,
              let data = imagePart?.body.asRaw else {
          return
        }
        let dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let fileURL = dir.appendingPathComponent("image-\(count)")
        let description = descriptionPart?.body.asText
        do {
          try data.write(to: fileURL, options: .atomic)
        }
        catch let error {
          print(error)
        }
        var valueTuples: [(Column, Any)] = [(userPhotosTable.userEmail, email),
                                            (userPhotosTable.photoUrl, fileURL.absoluteString)]
        if let description = description {
          valueTuples.append((userPhotosTable.description, description))
        }
        let insertQuery = Insert(into: userPhotosTable, valueTuples: valueTuples)
        connection.execute(query: insertQuery) { insertResult in
          print(insertResult)
          response.send("Success")
          next()
        }
      }
    }
  }
  fileprivate func downloadImage(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser else {
        return
    }
    do {
      let url = URL(fileURLWithPath: "image-4")
      let image = try Data(contentsOf: url)
      response.send(data: image); next()
    }
    catch let error {
      print(error)
    }
  }


}

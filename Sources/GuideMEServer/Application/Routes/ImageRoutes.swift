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
  app.router.post(Paths.image, middleware: BodyParser())
  app.router.post(Paths.image, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.post(Paths.image, handler: app.uploadImage)

  app.router.get(Paths.imageWithId, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.get(Paths.imageWithId, handler: app.downloadImage)
}

extension Backend {
  fileprivate func uploadImage(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let parts = request.body?.asMultiPart,
          let imagePart = parts.filter({ $0.type.contains("image") }).first,
          let imageData = imagePart.body.asRaw,
          let email = request.authorizedUser else {
      return
    }

    if let imageCount = DBUserPhotosModel.getUploadedPhotosCount() {
      let dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      let fileName = "image-\(imageCount)"
      let fileURL = dir.appendingPathComponent(fileName)
      let description = parts.filter({ $0.name == "description" }).first?.body.asText

      try imageData.write(to: fileURL, options: .atomic)

      let dbPhoto = DBUserPhotosModel(id: nil,
                                      userEmail: email,
                                      photoUri: fileName,
                                      description: description,
                                      likeCount: 0,
                                      timestamp: Date().millisecondsSince1970)
      dbPhoto.save { result, error in
        if let error = error {
          print(error)
          try? response.send(status: .internalServerError).end(); next()
        } else if result != nil {
          try? response.send("Success").end(); next()
        }
      }
    }
  }
  
  fileprivate func downloadImage(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard request.authorizedUser != nil,
          let file = request.parameters["imageId"] else {
        return
    }
    do {
      let url = URL(fileURLWithPath: file)
      let image = try Data(contentsOf: url)
      try response.send(data: image).end(); next()
    }
    catch let error {
      print(error)
      try response.send(status: .noContent).end(); next()
    }
  }
}

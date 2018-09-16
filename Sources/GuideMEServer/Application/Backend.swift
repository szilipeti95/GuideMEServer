import CryptoSwift
import Foundation
import Kitura
import SwiftJWT
import SwiftKuery
import SwiftKueryMySQL

public class Backend {
  let router = Router()

  let sqlUser = "app"
  let sqlPassword = "ppa"
  let sqlHost = "localhost"
  let sqlPort = 3306
  let sqlDatabase = "guideme"
  let pool: ConnectionPool!

  public init() throws {
    // Run the metrics initializer
    pool = MySQLConnection.createPool(url: URL(string: "mysql://\(sqlUser):\(sqlPassword)@\(sqlHost):\(sqlPort)/\(sqlDatabase)")!, poolOptions: ConnectionPoolOptions(initialCapacity: 10, maxCapacity: 50, timeout: 10000))
  }

  func postInit() throws {
    router.get("/") {
      request, response, next in
      print("/")
      response.send("Hello, World!")
      next()
    }

    router.get("/kaka") {
      request, response, next in

      print("/kaka called")
      /*

      let user = User(username: "Added1", password: "From", salt: "Kitura", email: "Server", fistName: "Swift", lastLame: "Backend", regDate: 11111, avatar: "asdf", backgroundAvatar: "asdf")
      user.save { _ , error in
        if let error = error {
          print(error)
          response.send("error")
          next()
          return
        }
      }

      response.send("Kaka")
      next()
       */
    }

    router.all("/kaka", middleware: BodyParser())

    router.post("/kaka") {
      request, response, next in

      print("/kaka called")
      guard let jsonBody = request.body?.asJSON else {
        response.send(request.body?.asText)
        next()
        return
      }
      let name = jsonBody["username"] as? String ?? ""
      let email = jsonBody["email"] as? String ?? ""
      let password = jsonBody["password"] as? String ?? ""
      try response.send("Hello \(name) \(email) \(password)").end()

      next()
    }

    addAuthRoutes(app: self)
    router.get("/photos/self") {
      request, response, next in
      guard let encodedAndSignedJWT = request.headers["Authorization"] else {
        response.send("No Authorization Header")
        next()
        return
      }
      print(encodedAndSignedJWT)
      let keyPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath + "/publicKey.key")
      print(keyPath.absoluteString)
      let key: Data = try Data(contentsOf: keyPath, options: .alwaysMapped)
      if try !JWT.verify(encodedAndSignedJWT, using: .rs256(key, .publicKey)) {
        response.send("Authorization Error")
        next()
        return
      }


      response.send("Auth success")
      next()
    }
  }

  public func run() throws {
    try postInit()

    // Add an HTTP server and connect it to the router
    #if os(Linux)
    let myCertFile = "/etc/letsencrypt/live/mylittlebackend.ml/cert.pem"
    let myKeyFile = "/etc/letsencrypt/live/mylittlebackend.ml/privkey.pem"

    let mySSLConfig =  SSLConfig(withCACertificateDirectory: nil,
                                 usingCertificateFile: myCertFile,
                                 withKeyFile: myKeyFile,
                                 usingSelfSignedCerts: true)


    Kitura.addHTTPServer(onPort: 8004, with: router, withSSL: mySSLConfig)
    #else // on macOS

    Kitura.addHTTPServer(onPort: 8004, with: router)
    #endif

    let localRouter = Router()
    localRouter.get("/shutdown") {
      request, response, next in
      response.send("Stopping server!")
      Kitura.stop()
    }

    Kitura.addHTTPServer(onPort: 8084, with: localRouter)

    // Start the Kitura runloop (this call never returns)
    Kitura.run()

  }
}

//let connection = MySQLConnection(host: host, user: user, password: password, database: database, port: port, characterSet: "UTF-8")



// Create a new router


// Handle HTTP GET requests to /



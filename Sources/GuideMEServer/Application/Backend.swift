import CryptoSwift
import Foundation
import Kitura
import SwiftJWT
import SwiftKuery
import SwiftKueryMySQL
import SwiftKueryORM

public class Backend {
  let router = Router()

  let sqlUser = "app"
  let sqlPassword = "ppa"
  let sqlHost = "localhost"
  let sqlPort = 3306
  let sqlDatabase = "guideme"

  public init() throws {
    // Run the metrics initializer
    let pool = MySQLConnection.createPool(url: URL(string: "mysql://\(sqlUser):\(sqlPassword)@\(sqlHost):\(sqlPort)/\(sqlDatabase)")!, poolOptions: ConnectionPoolOptions(initialCapacity: 10, maxCapacity: 50, timeout: 10000))
    Database.default = Database(pool)
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
    }

    router.all("/kaka", middleware: BodyParser())

    router.post("/kaka") {
      request, response, next in

      print("/kaka called")
      /*
       Database.default = Database(pool)
       let user = User(id: 2, username: "Added1", password: "From", salt: "Kitura", email: "Server", fistName: "Swift", lastLame: "Backend", regDate: 11111, avatar: "asdf", backgroundAvatar: "asdf")
       user.save { _ , error in
       if let error = error {
       print(error)
       }
       }
       */
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

    router.all("/auth/register", middleware: BodyParser())
    router.post("/auth/register") {
      request, response, next in

      guard let jsonBody = request.body?.asJSON else {
        response.send(request.body?.asText)
        next()
        return
      }

      let username = jsonBody["username"] as? String ?? ""
      let email = jsonBody["email"] as? String ?? ""
      let password = jsonBody["password"] as? String ?? ""

      if username == "" || email == "" || password == "" {
        response.send("error")
        next()
      }

      let regDate = Int(Date().timeIntervalSince1970)
      let passwordHash = password.sha256()
      let passwordArray: Array<UInt8> = Array(passwordHash.utf8)
      let saltHash = self.randomString(length: 64)
      let saltArray: Array<UInt8> = Array(saltHash.utf8)
      let key = try PKCS5.PBKDF2.init(password: passwordArray, salt: saltArray, iterations: 4096, keyLength: 32, variant: .sha256).calculate().toHexString()
      print(key)
      let user = User(username: username,
                      password: key,
                      salt: saltHash,
                      email: email,
                      fistName: nil,
                      lastLame: nil,
                      regDate: regDate,
                      avatar: nil,
                      backgroundAvatar: nil)
      user.save { _ , error in
        if let error = error {
          print(error)
        }

        response.send("siker")
        next()
      }
    }
    router.all("/auth/login", middleware: BodyParser())
    router.post("/auth/login") {
      request, response, next in

      guard let jsonBody = request.body?.asJSON else {
        response.send(request.body?.asText)
        next()
        return
      }

      let username = jsonBody["username"] as? String ?? ""
      let password = jsonBody["password"] as? String ?? ""

      let passwordHash = password.sha256()
      let passwordArray: Array<UInt8> = Array(passwordHash.utf8)

      User.findAll { array, error in
        if let array = array {
          var selectedUser: User?
          for user in array {
            if user.username == username {
              selectedUser = user
            }
          }
          if selectedUser != nil {
            let saltArray: Array<UInt8> = Array(selectedUser!.salt.utf8)
            do {
              let key = try PKCS5.PBKDF2.init(password: passwordArray, salt: saltArray, iterations: 4096, keyLength: 32, variant: .sha256).calculate().toHexString()

              if key == selectedUser!.password {
                response.send("good pass")
                next()
                return
              } else {
                response.send("wrong pass")
                next()
                return
              }

            } catch _ {

            }
          }
          else {
            response.send("no user")
            next()
            return
          }
        }

      }

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

  func randomString(length: Int) -> String {

    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let len = UInt32(letters.length)

    var randomString = ""

    for _ in 0 ..< length {
      let rand = arc4random_uniform(len)
      var nextChar = letters.character(at: Int(rand))
      randomString += NSString(characters: &nextChar, length: 1) as String
    }

    return randomString
  }
}

//let connection = MySQLConnection(host: host, user: user, password: password, database: database, port: port, characterSet: "UTF-8")



// Create a new router


// Handle HTTP GET requests to /



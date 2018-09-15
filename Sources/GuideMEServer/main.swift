import Foundation
import Kitura
import SwiftJWT
import SwiftKuery
import SwiftKueryMySQL
import SwiftKueryORM

let sqlUser = "app"
let sqlPassword = "ppa"
let sqlHost = "localhost"
let sqlPort = 3306
let sqlDatabase = "guideme"

//let connection = MySQLConnection(host: host, user: user, password: password, database: database, port: port, characterSet: "UTF-8")

let pool = MySQLConnection.createPool(url: URL(string: "mysql://\(sqlUser):\(sqlPassword)@\(sqlHost):\(sqlPort)/\(sqlDatabase)")!, poolOptions: ConnectionPoolOptions(initialCapacity: 10, maxCapacity: 50, timeout: 10000))
Database.default = Database(pool)

// Create a new router

let router = Router()

// Handle HTTP GET requests to /
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
  print(regDate)
  let user = User(username: username,
                  password: password,
                  salt: "kitura",
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



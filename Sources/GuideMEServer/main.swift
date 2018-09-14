import Kitura
import SwiftKuery
import SwiftKueryMySQL
import SwiftKueryORM
import Foundation

let user = "app"
let password = "ppa"
let host = "localhost"
let port = 3306
let database = "guideme"

//let connection = MySQLConnection(host: host, user: user, password: password, database: database, port: port, characterSet: "UTF-8")

let pool = MySQLConnection.createPool(url: URL(string: "mysql://\(user):\(password)@\(host):\(port)/\(database)")!, poolOptions: ConnectionPoolOptions(initialCapacity: 10, maxCapacity: 50, timeout: 10000))


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
  //let user = Table(tableName: "User", columns: [Column("username", String.self), Column("email", String.self), Column("reg_date", Int64.self)])
  /*
  let user = User()
  let newUser: [[Any]] = [["Added", "From", 11111]]
  if let connection = pool.getConnection() {
    let insertQuery = Insert(into: user, columns: [Column("username", String.self), Column("email", String.self), Column("reg_date", Int64.self)], rows: newUser, returnID: false)
    connection.execute(query: insertQuery) { insertResult in
      connection.execute(query: Select(from: user)) { selectResult in
        if let resultSet = selectResult.asResultSet {
          for row in resultSet.rows {
            print("username: \(row[0]) email: \(row[1])")
          }
        }
        connection.commit { _ in
          response.send("Kaka")
          next()
        }
      }
    }
  }
 */
  Database.default = Database(pool)
  let user = User(id: 2, username: "Added1", password: "From", salt: "Kitura", email: "Server", fistName: "Swift", lastLame: "Backend", regDate: 11111, avatar: "asdf", backgroundAvatar: "asdf")
  user.save { _ , error in
    if let error = error {
      print(error)
    }
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



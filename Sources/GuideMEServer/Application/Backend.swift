import CryptoSwift
import Foundation
import Kitura
import SwiftJWT
import SwiftKuery
import SwiftKueryMySQL
import SwiftKueryORM
import KituraWebSocket
import Credentials
import CredentialsGoogle
import CredentialsFacebook

public class Backend {
  let router = Router()
  let adminRouter = Router()
  #if os(Linux)
  let sqlUser = "app"
  let sqlPassword = "ppa"
  let sqlHost = "localhost"
  let sqlDatabase = "guideme"
  #else
  let sqlUser = "root"
  let sqlPassword = "toor"
  let sqlHost = "127.0.0.1"
  let sqlDatabase = "guideme"
  #endif
  let sqlPort = 3306
  let pool: ConnectionPool!
  let publicKeyPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath + "/publicKey.key")
  static var publicKey: Data!
  let privateKeyPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath + "/privateKey.key")
  let privateKey: Data!
  let tokenCredentials: Credentials!
  public init() throws {
    pool = MySQLConnection.createPool(url: URL(string: "mysql://\(sqlUser):\(sqlPassword)@\(sqlHost):\(sqlPort)/\(sqlDatabase)")!,
                                      poolOptions: ConnectionPoolOptions(initialCapacity: 10,
                                                                         maxCapacity: 50))
    Database.default = Database(pool)
    tokenCredentials = Credentials()
    tokenCredentials.register(plugin: CredentialsJWTToken())
    tokenCredentials.register(plugin: CredentialsGoogleToken())
    tokenCredentials.register(plugin: CredentialsFacebookToken(options: ["fields": "name,email"]))
    print(publicKeyPath)
    Backend.publicKey = try Data(contentsOf: publicKeyPath, options: .alwaysMapped)
    privateKey = try Data(contentsOf: privateKeyPath, options: .alwaysMapped)
  }

  func postInit() throws {
    checkTables()

    addAdminRoutes(app: self)
    addAuthRoutes(app: self)
    addUserRoutes(app: self)
    addMessageRoutes(app: self)
    addImagesRoutes(app: self)
    addGuideRoutes(app: self)
  }

  private func checkTables() {
    do {
      try DBUserModel.createTableSync()
    } catch let error {
      print(error)
    }

    do {
//      try User.createTableSync()
      try DBUserPhotosModel.createTableSync()
    } catch let error {
      print(error)
    }

    do {
      try DBConversationModel.createTableSync()
    } catch let error {
      print(error)
    }
    do {
      try DBCitiesModel.createTableSync()
    } catch let error {
      print(error)
    }
    do {
      try DBGuidesModel.createTableSync()
    } catch let error {
      print(error)
    }
  }

  public func run() throws {
    try postInit()

    #if os(Linux)
    let myCertFile = "/etc/letsencrypt/live/mylittlebackend.ml/cert.pem"
    let myKeyFile = "/etc/letsencrypt/live/mylittlebackend.ml/privkey.pem"

    let mySSLConfig =  SSLConfig(withCACertificateDirectory: nil,
                                 usingCertificateFile: myCertFile,
                                 withKeyFile: myKeyFile,
                                 usingSelfSignedCerts: true)


    Kitura.addHTTPServer(onPort: 8044, with: router, withSSL: mySSLConfig)
    #else

    Kitura.addHTTPServer(onPort: 8044, with: router)
    #endif

    Kitura.addHTTPServer(onPort: 8084, with: adminRouter)

    Kitura.run()
  }

  func startConnection(response: RouterResponse, _  closure: @escaping ((ConnectionPoolConnection) -> Void)) {
    pool.getConnection { connection, error in
      if let error = error {
        print(error)
        response.send(nil).status(.internalServerError)
      } else if let connection = connection {
        closure(connection)
      } else {
        response.send(nil).status(.internalServerError)
      }
    }
  }

  func map(dicts: [[String: Any?]], key: String, columns: [String]) -> [[String: Any?]] {
    var mappedDicts = [[String: Any?]]()
    var addedString = [Int32]()
    for dict in dicts {
      let skey = dict[key] as! Int32
      print(skey)
      if !addedString.contains(skey) {
        var newDict = dict
        for column in columns {
          var newArray = [Int]()
          newArray.append(Int(newDict[column] as! Int32))
          newDict[column] = newArray
        }
        mappedDicts.append(newDict)
        addedString.append(skey)
      } else {
        var appendDict = mappedDicts.first { $0[key] as! Int32 == dict[key] as! Int32 }
        let index = mappedDicts.index(where: { $0[key] as! Int32 == dict[key] as! Int32  })
        for column in columns {
          var newArray = appendDict?[column] as! [Int]
          newArray.append(Int(dict[column] as! Int32))
          appendDict?[column] = newArray
        }
        mappedDicts[index!] = appendDict!
      }
    }
    return mappedDicts
  }
}

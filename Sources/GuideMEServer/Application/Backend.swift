import CryptoSwift
import Foundation
import Kitura
import SwiftJWT
import SwiftKuery
import SwiftKueryMySQL
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
  #else
  let sqlUser = "internalAPI"
  let sqlPassword = "IPAlanretni"
  let sqlHost = "127.0.0.1"
  #endif
  let sqlPort = 4306
  let sqlDatabase = "guideme_new"
  let pool: ConnectionPool!
  let publicKeyPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath + "/publicKey.key")
  static var publicKey: Data!
  let privateKeyPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath + "/privateKey.key")
  let privateKey: Data!
  let tokenCredentials: Credentials!
  public init() throws {
    pool = MySQLConnection.createPool(url: URL(string: "mysql://\(sqlUser):\(sqlPassword)@\(sqlHost):\(sqlPort)/\(sqlDatabase)")!,
                                      poolOptions: ConnectionPoolOptions(initialCapacity: 10,
                                                                         maxCapacity: 50,
                                                                         timeout: 10000))
    tokenCredentials = Credentials()
    tokenCredentials.register(plugin: CredentialsJWTToken())
    tokenCredentials.register(plugin: CredentialsGoogleToken())
    tokenCredentials.register(plugin: CredentialsFacebookToken(options: ["fields": "name,email"]))
    print(publicKeyPath)
    Backend.publicKey = try Data(contentsOf: publicKeyPath, options: .alwaysMapped)
    privateKey = try Data(contentsOf: privateKeyPath, options: .alwaysMapped)
  }

  func postInit() throws {
    addAdminRoutes(app: self)
    addAuthRoutes(app: self)
    addUserRoutes(app: self)
    addMessageRoutes(app: self)
    addImagesRoutes(app: self)
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


    Kitura.addHTTPServer(onPort: 8004, with: router, withSSL: mySSLConfig)
    #else

    Kitura.addHTTPServer(onPort: 8004, with: router)
    #endif

    Kitura.addHTTPServer(onPort: 8084, with: adminRouter)

    Kitura.run()
  }
}

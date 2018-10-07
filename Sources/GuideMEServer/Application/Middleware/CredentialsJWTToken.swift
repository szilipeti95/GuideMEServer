//
//  JWTTypeSafe.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 07..
//

import Kitura
import KituraNet
import Credentials
import Foundation
import SwiftJWT

public class CredentialsJWTToken: CredentialsPluginProtocol {
  public var usersCache: NSCache<NSString, BaseCacheElement>?


  /// The name of the plugin.
  public var name: String {
    return "JWTToken"
  }

  /// An indication as to whether the plugin is redirecting or not.
  public var redirecting: Bool {
    return false
  }

  public func authenticate(request: RouterRequest, response: RouterResponse,
                           options: [String:Any], onSuccess: @escaping (UserProfile) -> Void,
                           onFailure: @escaping (HTTPStatusCode?, [String:String]?) -> Void,
                           onPass: @escaping (HTTPStatusCode?, [String:String]?) -> Void,
                           inProgress: @escaping () -> Void) {
    if let type = request.headers["X-token-type"], type == name {
      print("middleware")
      guard let encodedAndSignedJWT = request.headers["access_token"] else {
        onFailure(.badRequest, nil)
        return
      }
      guard try! JWT.verify(encodedAndSignedJWT, using: .rs256(Backend.publicKey, .publicKey)) else {
        onFailure(.unauthorized, nil)
        return
      }
      guard let user = try? JWT.decode(encodedAndSignedJWT) else {
        onFailure(.internalServerError, nil)
        return
      }
      let userProfile = UserProfile(id: "", displayName: "", provider: name)
      userProfile.emails = [UserProfile.UserProfileEmail]()
      userProfile.emails?.append(UserProfile.UserProfileEmail(value: (user?.claims[.email] as? String)!, type: ""))
      onSuccess(userProfile)
    }
    else {
      onPass(nil, nil)
    }
  }
}

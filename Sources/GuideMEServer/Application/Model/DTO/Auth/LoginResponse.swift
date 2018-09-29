//
//  LoginResponse.swift
//  Application
//
//  Created by Szili Péter on 2018. 09. 29..
//

import Foundation

class LoginResponse: Codable {
  var jwt: String

  init(jwt: String) {
    self.jwt = jwt
  }

  enum CodingKeys: String, CodingKey {
    case jwt
  }
}

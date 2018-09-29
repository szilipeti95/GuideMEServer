//
//  LoginRequest.swift
//  Application
//
//  Created by Szili Péter on 2018. 09. 29..
//

import Foundation

class LoginRequest: Codable {
  var username: String
  var password: String

  enum CodingKeys: String, CodingKey {
    case username
    case password
  }
}

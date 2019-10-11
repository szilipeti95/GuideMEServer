//
//  LoginRequest.swift
//  Application
//
//  Created by Szili Péter on 2018. 09. 29..
//

import Foundation

struct LoginRequestDTO: Codable {
  var email: String
  var password: String

  enum CodingKeys: String, CodingKey {
    case email
    case password
  }
}

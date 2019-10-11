//
//  LoginResponse.swift
//  Application
//
//  Created by Szili Péter on 2018. 09. 29..
//

import Foundation

struct LoginResponseDTO: Codable {
  var jwt: String

  enum CodingKeys: String, CodingKey {
    case jwt
  }
}

//
//  RegisterRequest.swift
//  Application
//
//  Created by Szili Péter on 2018. 09. 29..
//

import Foundation

struct RegisterRequest: Codable {
  var firstName: String
  var lastName: String
  var email: String
  var password: String

  enum CodingKeys: String, CodingKey {
    case firstName = "first_name"
    case lastName = "last_name"
    case email
    case password
  }
}

extension RegisterRequest {
  var isValid: Bool {
    get {
      if firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty {
        return false
      }
      return true
    }
  }
}

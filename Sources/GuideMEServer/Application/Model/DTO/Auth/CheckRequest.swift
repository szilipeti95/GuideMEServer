//
//  checkRequest.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 07..
//

import Foundation

struct CheckRequest: Codable {
  var email: String

  enum CodingKeys: String, CodingKey {
    case email
  }
}

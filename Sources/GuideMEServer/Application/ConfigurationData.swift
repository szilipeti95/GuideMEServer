//
//  ConfigurationData.swift
//  Application
//
//  Created by Szili Péter on 2019. 12. 14..
//

import Foundation

class ConfigurationData: Codable {
  let sqlUser: String
  let sqlPassword: String
  let sqlHost: String
  let sqlDatabase: String
  let sqlPort: Int
  let publicPort: Int
  let privatePort: Int
}

//
//  main.swift
//  CHTTPParser
//
//  Created by Szili Péter on 2018. 09. 15..
//

import Foundation
import Kitura
import Application

do {
  let app = try Backend()
  try app.run()
} catch _ {
}


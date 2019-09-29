//
//  Helper.swift
//  Application
//
//  Created by Szili Péter on 2019. 09. 29..
//

import Foundation
import Kitura
import SwiftKuery

extension QueryResult {
  var getRows: [[String: Any?]]? {
    var rows: [[String: Any?]]?
    asRows { rowsResult, error in
      rows = rowsResult
    }
    return rows
  }
}

//
//  Helper.swift
//  Application
//
//  Created by Szili Péter on 2019. 09. 29..
//

import Foundation
import Kitura
import SwiftKuery
import SwiftKueryORM
import SwiftKueryMySQL

extension QueryResult {
  var getRows: [[String: Any?]]? {
//    let wait = DispatchSemaphore(value: 0)
    var rows: [[String: Any?]]?
    asRows { rowsResult, error in
      rows = rowsResult
//      wait.signal()
      return
    }
//    wait.wait()
    return rows
  }
}

enum PSKueryException: Error {
  case noColumnExists(named: String)
}

extension Table {
  subscript(index: String) -> Column? {
    return self.columns.first(where: { $0.name == index })
  }
}

protocol TableFinder {
  associatedtype CodingEnum: (CodingKey)

  static func getColumn(_ enumValue: CodingEnum) throws -> Column
}


extension TableFinder where Self: Model {
  static func getColumn(_ enumValue: CodingEnum) throws -> Column {
    let table = try getTable()
    guard let column = table[enumValue.stringValue] else {
      throw PSKueryException.noColumnExists(named: enumValue.stringValue)
    }

    return column
  }
}

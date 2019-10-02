//
//  Helper.swift
//  Application
//
//  Created by Szili Péter on 2019. 09. 29..
//

import SwiftKuery
import SwiftKueryORM

enum PSKueryException: Error {
  case noColumnExists(named: String)
}

extension Table {
  subscript(index: String) -> Column? {
    return self.columns.first(where: { $0.name == index })
  }
}

extension Model {
  public static func tryCreateTableSync() {
    do {
      try createTableSync()
    } catch let error {
      print(error)
    }
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

//
//  Date+Milliseconds.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 15..
//

import Foundation

extension Date {
  var millisecondsSince1970:Int {
    return Int((self.timeIntervalSince1970 * 1000.0).rounded())
  }

  init(milliseconds:Int) {
    self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
  }
}

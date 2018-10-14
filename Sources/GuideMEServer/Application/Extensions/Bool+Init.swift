//
//  Bool+Init.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 14..
//

import Foundation

extension Bool {
  init<T: BinaryInteger>(_ num: T) {
    self.init(num != 0)
  }
}

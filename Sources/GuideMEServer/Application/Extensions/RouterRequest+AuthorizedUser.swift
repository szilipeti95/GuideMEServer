//
//  RouterRequest+AuthorizedUser.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 07..
//

import Foundation
import Kitura

extension RouterRequest {
  var authorizedUser: String? {
    get {
      return self.userProfile?.emails?[0].value ?? self.userProfile?.id
    }
  }
}

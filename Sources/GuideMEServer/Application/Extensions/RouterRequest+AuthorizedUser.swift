//
//  RouterRequest+AuthorizedUser.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 07..
//

import Foundation
import Kitura

extension RouterRequest {
  var authorizedUser: UserDTO? {
    get {
      guard let email = self.userProfile?.emails?[0].value else {
        return nil
      }
      return UserDTO.builder(email: email)
    }
  }
}


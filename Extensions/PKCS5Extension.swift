//
//  PKCS5Extension.swift
//  Application
//
//  Created by Szili Péter on 2018. 09. 16..
//

import Foundation
import CryptoSwift

extension PKCS5 {
  static func generatePassword(passwordArray: Array<UInt8>, saltArray: Array<UInt8>) -> String {
    do {
      let key = try PKCS5.PBKDF2.init(password: passwordArray, salt: saltArray, iterations: 4096, keyLength: 32, variant: .sha256).calculate().toHexString()
      return key
    } catch {
      print("error during key generation")
      return ""
    }
  }
}

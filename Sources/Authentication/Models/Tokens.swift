//
//  Tokens.swift
//  APIAccess
//
//  Created by Andy Bezaire on 3.3.2021.
//

import Foundation

extension Auth {
    typealias Token = String
    typealias Refresh = String

    struct Tokens {
        let token: Token
        let refresh: Refresh?
    }
}

//
//  Tokens.swift
//  APIAccess
//
//  Created by Andy Bezaire on 3.3.2021.
//

import Foundation

public extension Auth {
    typealias Token = String
    typealias Refresh = String

    struct Tokens {
        public let token: Token
        public let refresh: Refresh?
        public init(token: Token, refresh: Refresh?) {
            self.token = token
            self.refresh = refresh
        }
    }
}

extension Auth.Tokens: CustomStringConvertible {
    public var description: String {
        "token: \(token), refresh: \(refresh ?? "nil")"
    }
}

//
//  Error.swift
//  APIAccess
//
//  Created by Andy Bezaire on 3.3.2021.
//

import Foundation

public extension Auth {
    enum Error: Swift.Error {
        case tokenExpired
        case tokenNil
    }
}

extension Auth.Error: LocalizedError {
    public var errorDescription: String? {
            switch self {
            case .tokenExpired:
                return "Token expired."
            case .tokenNil:
                return "Token nil."
            }
        }
}

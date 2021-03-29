//
//  Error.swift
//  APIAccess
//
//  Created by Andy Bezaire on 3.3.2021.
//

import Foundation

public extension Auth {
    enum Error: Swift.Error {
        case signInFailed(Swift.Error)
        case tokenExpired
        case tokenNil
        case urlError(URLError)
        case signOutFailed(Swift.Error)
        case unknown
    }
}

extension Auth.Error: LocalizedError {
    public var errorDescription: String? {
            switch self {
            case .signInFailed(let error):
                return "Sign in failed (\(error.localizedDescription))."
            case .tokenExpired:
                return "Token expired."
            case .tokenNil:
                return "Token nil."
            case .urlError(let error):
                return "Request failed (\(error.localizedDescription))."
            case .signOutFailed(let error):
                return "Sign out failed (\(error.localizedDescription))."
            case .unknown:
                return "Unknown error."
            }
        }
}

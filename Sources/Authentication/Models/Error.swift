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
        case urlError(URLError)
        case unknown
    }
}

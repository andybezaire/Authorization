//
//  Status.swift
//
//
//  Created by Andy Bezaire on 19.3.2021.
//

import Foundation

public extension Auth {
    enum Status {
        case signedIn, signedInNoRefresh, notSignedIn, signingIn, refreshingToken
    }
}

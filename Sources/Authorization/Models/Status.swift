//
//  Status.swift
//
//
//  Created by Andy Bezaire on 19.3.2021.
//

import Foundation

public extension Auth {
    enum Status {
        case signedIn, signedInNoRefresh, notSignedIn, signedInTokenExpired, signingIn, refreshingToken, signingOut
    }
}

extension Auth {
    func assignStatusFromTokens() {
        updatingStatusFromTokens = token
            .combineLatest(refresh)
            .map { token, refresh in
                switch (token, refresh) {
                case (.none, _):
                    return .notSignedIn
                case (.some, .some):
                    return .signedIn
                case (.some, .none):
                    return .signedInNoRefresh
                }
            }
            .subscribe(_status)
    }
}

extension Auth.Status: CustomStringConvertible {
    public var description: String {
        switch self {
        case .signedIn:
            return "Signed in."
        case .signedInNoRefresh:
            return "Signed in (No refresh)."
        case .notSignedIn:
            return "NOT signed in"
        case .signedInTokenExpired:
            return "Signed in (Token expired)."
        case .signingIn:
            return "Signing in..."
        case .refreshingToken:
            return "Refreshing token..."
        case .signingOut:
            return "Signing out..."
        }
    }
}

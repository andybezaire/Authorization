//
//  Status.swift
//
//
//  Created by Andy Bezaire on 19.3.2021.
//

import Foundation

public extension Auth {
    enum Status {
        case signedIn, signedInNoRefresh, notSignedIn, signingIn, refreshingToken, signingOut
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
            .sink { [unowned self] in
                _status.send($0)
            }
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
        case .signingIn:
            return "Signing in..."
        case .refreshingToken:
            return "Refreshing token..."
        case .signingOut:
            return "Signing out..."
        }
    }
}

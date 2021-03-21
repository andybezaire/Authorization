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

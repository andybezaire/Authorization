//
//  ContentViewModel.swift
//  BasicLogin
//
//  Created by Andy Bezaire on 20.3.2021.
//

import Authentication
import Combine
import Foundation
import os.log

extension ContentView {
    class Model: ObservableObject {
        lazy var auth = Auth(
            doGetTokens: doGetTokens,
            doRefreshToken: doRefreshTokens,
            logger: Logger(subsystem: "com.example.BasicLogin", category: "auth")
        )

        internal var signInOut: AnyCancellable?

        @Published private var _status: Auth.Status = .notSignedIn
        var status: String {
            "\(_status)"
        }

        @Published var error: String?

        @Published var callback: Callback?

        var isSignedIn: Bool {
            _status == .signedIn || _status == .signedInNoRefresh || _status == .refreshingToken
        }

        internal var fetching: AnyCancellable?

        @Published var isNetworkFailures = false
        @Published var isTokenExpired = false

        @Published var fetchStatus: String?

        init() {
            auth.status
                .receive(on: RunLoop.main)
                .assign(to: &$_status)
        }
    }
}

extension Auth.Status: CustomStringConvertible {
    public var description: String {
        switch self {
        case .signedIn:
            return "Signed in."
        case .signedInNoRefresh:
            return "Signed in (no refresh)."
        case .notSignedIn:
            return "NOT signed in."
        case .signingIn:
            return "signing in..."
        case .refreshingToken:
            return "refreshing token..."
        case .signingOut:
            return "signing out..."
        }
    }
}

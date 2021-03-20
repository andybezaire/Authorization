//
//  ContentViewModel.swift
//  BasicLogin
//
//  Created by Andy Bezaire on 20.3.2021.
//

import Authentication
import Combine
import Foundation

extension ContentView {
    class Model: ObservableObject {
        private let auth: Auth
        private var signInOut: AnyCancellable?

        @Published private var _status: Auth.Status = .notSignedIn

        var status: String {
            switch _status {
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

        @Published var error: String?

        init() {
            auth = Auth(
                doGetTokens: {
                    Just<Auth.Tokens>(Auth.Tokens(token: "TOKEN", refresh: "REFRESH"))
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                },
                doRefreshToken: { _ in
                    Just<Auth.Tokens>(Auth.Tokens(token: "TOKEN", refresh: "REFRESH"))
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
            )

            auth.status
                .assign(to: &$_status)
        }

        func signIn() {
            signInOut = auth.signIn()
                .sink(receiveCompletion: { [unowned self] in
                    handle(completion: $0)
                }, receiveValue: { _ in })
        }

        func signOut() {
            signInOut = auth.signOut()
                .sink(receiveCompletion: { [unowned self] in
                    handle(completion: $0)
                }, receiveValue: { _ in })
        }

        private func handle(completion: Subscribers.Completion<Auth.Error>) {
            switch completion {
            case .failure(let authError):
                switch authError {
                case .signInFailed:
                    error = "Sign in failed!"
                case .tokenExpired:
                    error = "Token expired!"
                case .urlError:
                    error = "URL Error!"
                case .signOutFailed:
                    error = "Sign out failed!"
                case .unknown:
                    error = "Unknown error!!!"
                }
            case .finished:
                error = nil
            }
        }
    }
}

//
//  SignIn.swift
//  APIAccess
//
//  Created by Andy Bezaire on 3.3.2021.
//

import Combine
import Foundation

public extension Auth {
    /// sign in and get tokens.
    /// - Returns: publisher that never sends a value only a completion with error if fail
    func signIn() -> AnyPublisher<Void, Error> {
        doGetTokens()
            .mapError { Error.signInFailed($0) }
            .handleEvents(
                receiveOutput: {
                    self.tokenSubject.send($0.token)
                    self.refreshSubject.send($0.refresh)
                },
                receiveCompletion: {
                    switch $0 {
                    case .finished: break
                    case .failure:
                        self.tokenSubject.send(nil)
                        self.refreshSubject.send(nil)
                    }
                }
            )
            .log(to: logger, prefix: "SignIn") { logger, output in
                logger.log("SignIn got token \(output.token, privacy: .private)")
                logger.log("SignIn got refresh \(output.refresh ?? "nil", privacy: .private)")
            }
            .flatMap { _ in Empty<Void, Error>().eraseToAnyPublisher() }
            .eraseToAnyPublisher()
    }
}

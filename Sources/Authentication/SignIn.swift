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
        _status = .signingIn
        return doGetTokens()
            .mapError { Error.signInFailed($0) }
            .handleEvents(
                receiveOutput: { [unowned self] in
                    tokenSubject.send($0.token)
                    refreshSubject.send($0.refresh)
                },
                receiveCompletion: { [unowned self] in
                    switch $0 {
                    case .finished: break
                    case .failure:
                        tokenSubject.send(nil)
                        refreshSubject.send(nil)
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

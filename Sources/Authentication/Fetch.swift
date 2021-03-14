//
//  Fetch.swift
//  APIAccess
//
//  Created by Andy Bezaire on 3.3.2021.
//

import Combine
import Foundation

extension Auth {
    public func fetch(_ request: URLRequest) -> AnyPublisher<URLResult, Error> {
        token
            .tryMap(tryUnwrapToken)
            .mapError(toAuthError)
            .map(useTokenToSign(request: request))
            .flatMap(fetchURLResultForRequest)
            .flatMap(refreshTokensIfNeeded)
            .first()
            .eraseToAnyPublisher()
    }

    private func toAuthError(error: Swift.Error) -> Error {
        switch error {
        case let authError as Error:
            return authError
        default:
            return .unknown
        }
    }

    private func useTokenToSign(request: URLRequest) -> ((Token) -> URLRequest) {
        return { token in
            self.signRequest(request, token)
        }
    }

    private func fetchURLResultForRequest(request: URLRequest) -> AnyPublisher<URLResult, Error> {
        URLSession.shared.dataTaskPublisher(for: request)
            .mapError { Error.urlError($0) }
            .eraseToAnyPublisher()
    }

    private func refreshTokensIfNeeded(result: URLResult) -> AnyPublisher<URLResult, Error> {
        if shouldDoRefreshFor(result) {
            refreshTokens()
            return Empty()
                .eraseToAnyPublisher()
        } else {
            return Just(result)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
}

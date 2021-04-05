//
//  Fetch.swift
//  APIAccess
//
//  Created by Andy Bezaire on 3.3.2021.
//

import Combine
import Foundation

extension Auth {
    public func fetch(_ request: URLRequest) -> AnyPublisher<URLResult, Swift.Error> {
        token
            .tryMap(tryUnwrapToken)
            .map(useTokenToSign(request: request))
            .flatMap(fetchURLResultForRequest)
            .flatMap(refreshTokensIfNeeded)
            .merge(with: tokenExpired)
            .first()
            .eraseToAnyPublisher()
    }

    private func useTokenToSign(request: URLRequest) -> ((Token) -> URLRequest) {
        return { token in
            self.signRequest(request, token)
        }
    }

    private func fetchURLResultForRequest(request: URLRequest) -> AnyPublisher<URLResult, Swift.Error> {
        URLSession.shared.dataTaskPublisher(for: request)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }

    private func refreshTokensIfNeeded(result: URLResult) -> AnyPublisher<URLResult, Swift.Error> {
        if shouldDoRefreshFor(result) {
            refreshTokens()
            return Empty()
                .eraseToAnyPublisher()
        } else {
            return Just(result)
                .setFailureType(to: Swift.Error.self)
                .eraseToAnyPublisher()
        }
    }
}

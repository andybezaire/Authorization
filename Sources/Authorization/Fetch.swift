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
            .log(to: logger, prefix: "Fetch \(request.description)") { logger, result in
                let code = (result.response as? HTTPURLResponse)?.statusCode ?? -1
                logger.log("Fetch \(request.description) response code \(code)")
            }
            .eraseToAnyPublisher()
    }

    private func useTokenToSign(request: URLRequest) -> ((Token) -> URLRequest) {
        return { token in
            self.signRequest(request, token)
        }
    }

    private func fetchURLResultForRequest(request: URLRequest) -> AnyPublisher<URLResult, Swift.Error> {
        URLSession.shared.dataTaskPublisher(for: request)
            .mapError { $0 as Swift.Error }
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

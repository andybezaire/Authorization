//
//  Auth.swift
//  APIAccess
//
//  Created by Andy Bezaire on 20.2.2021.
//

import Combine
import Foundation

public class Auth {
    public init(
        doGetTokens: @escaping () -> AnyPublisher<Tokens, Swift.Error>,
        doRefreshToken: @escaping (_ refresh: Refresh) -> AnyPublisher<Tokens, Swift.Error>,
        signRequest: @escaping (_ request: URLRequest, _ token: Token) -> URLRequest = Auth.signedWithBearerToken,
        shouldDoRefreshFor: @escaping (_ result: URLResult) -> Bool = Auth.isResponseCode403,
        tokenSubject: TokenValueSubject<Token?, Never> = TokenValueSubject<Token?, Never>(nil),
        refreshSubject: TokenValueSubject<Refresh?, Never> = TokenValueSubject<Refresh?, Never>(nil)
    ) {
        self.doGetTokens = doGetTokens
        self.doRefreshToken = doRefreshToken
        self.signRequest = signRequest
        self.shouldDoRefreshFor = shouldDoRefreshFor
        self.tokenSubject = tokenSubject
        self.refreshSubject = refreshSubject
    }

    let doGetTokens: () -> AnyPublisher<Tokens, Swift.Error>
    let doRefreshToken: (_ refresh: Refresh) -> AnyPublisher<Tokens, Swift.Error>
    let signRequest: (_ request: URLRequest, _ token: Token) -> URLRequest
    let shouldDoRefreshFor: (_ result: URLResult) -> Bool

    let tokenSubject: TokenValueSubject<Token?, Never>
    var token: AnyPublisher<Token?, Never> {
        return tokenSubject
            .eraseToAnyPublisher()
    }

    let refreshSubject: TokenValueSubject<Refresh?, Never>
    var refresh: AnyPublisher<Refresh?, Never> {
        return refreshSubject
            .eraseToAnyPublisher()
    }

    private var refreshingToken: AnyCancellable?
}

// MARK: - Refresh

extension Auth {
    func refreshTokens() {
        refreshingToken = Just(refreshSubject.value)
            .tryMap(tryUnwrapToken)
            .flatMap(doRefreshToken)
            .mapError { _ in Error.tokenExpired }
            .map { $0 as Tokens? }
            .replaceError(with: nil)
            .sink(receiveValue: saveInSubjects)
    }

    func tryUnwrapToken(optToken: String?) throws -> String {
        guard let token = optToken else { throw Error.tokenExpired }
        return token
    }

    private func saveInSubjects(tokens: Tokens?) {
        tokenSubject.send(tokens?.token)
        refreshSubject.send(tokens?.refresh)
    }
}

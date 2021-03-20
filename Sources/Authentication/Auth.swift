//
//  Auth.swift
//  APIAccess
//
//  Created by Andy Bezaire on 20.2.2021.
//

import Combine
import CombineExtras
import Foundation
import os.log

public class Auth {
    public init(
        doGetTokens: @escaping () -> AnyPublisher<Tokens, Swift.Error>,
        doRefreshToken: @escaping (_ refresh: Refresh) -> AnyPublisher<Tokens, Swift.Error>,
        signRequest: @escaping (_ request: URLRequest, _ token: Token) -> URLRequest = Auth.signedWithBearerToken,
        shouldDoRefreshFor: @escaping (_ result: URLResult) -> Bool = Auth.isResponseCode403,
        tokenSubject: TokenValueSubject<Token?, Never> = TokenValueSubject<Token?, Never>(nil),
        refreshSubject: TokenValueSubject<Refresh?, Never> = TokenValueSubject<Refresh?, Never>(nil),
        logger: Logger? = nil
    ) {
        self.doGetTokens = doGetTokens
        self.doRefreshToken = doRefreshToken
        self.signRequest = signRequest
        self.shouldDoRefreshFor = shouldDoRefreshFor
        self.tokenSubject = tokenSubject
        self.refreshSubject = refreshSubject
        self.logger = logger

        assignStatusFromTokens()
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

    @Published internal var _status: Status = .notSignedIn
    public var status: AnyPublisher<Status, Never> { $_status.eraseToAnyPublisher() }

    var logger: Logger?

    private var refreshingToken: AnyCancellable?
}

// MARK: - Refresh

extension Auth {
    func refreshTokens() {
        _status = .refreshingToken
        refreshingToken = Just(refreshSubject.value)
            .tryMap(tryUnwrapToken)
            .flatMap(doRefreshToken)
            .mapError { _ in Error.tokenExpired }
            .map { $0 as Tokens? }
            .replaceError(with: nil)
            .log(to: logger, prefix: "Fetch Refresh") { logger, output in
                logger.log("Fetch Refresh got token: \(output?.token ?? "nil", privacy: .private)")
                logger.log("Fetch Refresh got refresh: \(output?.refresh ?? "nil", privacy: .private)")
            }
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

// MARK: - Status

extension Auth {
    func assignStatusFromTokens() {
        token
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
            .assign(to: &$_status)
    }
}

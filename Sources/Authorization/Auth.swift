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

    // This is used when a refresh fails, in order to propagate the error
    internal let tokenError = PassthroughSubject<Void, Never>()
    var tokenExpired: AnyPublisher<URLResult, Error> {
        tokenError
            .tryMap { _ in throw Error.tokenExpired }
            .mapError { _ in Error.tokenExpired }
            .eraseToAnyPublisher()
    }

    internal let _status = CurrentValueSubject<Status, Never>(.notSignedIn)
    public var status: AnyPublisher<Status, Never> { _status.eraseToAnyPublisher() }

    var logger: Logger?

    internal var refreshingToken: AnyCancellable?

    internal var updatingStatusFromTokens: AnyCancellable?
}

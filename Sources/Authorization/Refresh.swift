//
//  File.swift
//
//
//  Created by Andy on 21.3.2021.
//

import Combine
import Foundation

extension Auth {
    /// [Refreshing Access Tokens](https://www.oauth.com/oauth2-servers/access-tokens/refreshing-access-tokens/)
    ///
    /// The response to the refresh token grant is the same as when issuing an access token.
    /// You can optionally issue a new refresh token in the response, or if you don’t include a new refresh token,
    ///  the client assumes the current refresh token will continue to be valid.
    /// - Parameter tokens: tokens to save
    func refreshTokens() {
        _status.send(.refreshingToken)

        refreshingToken = Just(refreshSubject.value)
            .tryMap(tryUnwrapToken)
            .flatMap(doRefreshToken)
            .catch { [unowned self] (_: Swift.Error) -> Empty<Tokens, Swift.Error> in
                tokenError.send(())
                _status.send(.signedInTokenExpired)
                return Empty()
            }
            .map { $0 }
            .replaceError(with: nil)
            .log(to: logger, prefix: "Fetch Refresh") { logger, output in
                let tokens = output.map { "\($0)" } ?? "nil"
                logger.log("Fetch Refresh got tokens: \(tokens, privacy: .private)")
            }
            .sink(receiveValue: saveInSubjects)
    }

    func tryUnwrapToken(optToken: String?) throws -> String {
        guard let token = optToken else { throw Error.tokenNil }
        return token
    }

    private func saveInSubjects(tokens: Tokens?) {
        tokenSubject.send(tokens?.token)
        if let refresh = tokens?.refresh {
            refreshSubject.send(refresh)
        }
    }
}

public extension Auth {
    /// Force `Auth` to refresh the tokens. This is intended to be used while debugging and not for normal use. 
    func forceTokenRefresh() {
        refreshTokens()
    }
}

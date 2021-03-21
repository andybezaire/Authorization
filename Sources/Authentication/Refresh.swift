//
//  File.swift
//
//
//  Created by Andy on 21.3.2021.
//

import Combine
import Foundation

extension Auth {
    func refreshTokens() {
        _status.send(.refreshingToken)

        refreshingToken = Just(refreshSubject.value)
            .tryMap(tryUnwrapToken)
            .flatMap(doRefreshToken)
            .catch { [unowned self] (_: Swift.Error) -> Empty<Tokens, Swift.Error> in
                tokenError.send(())
                return Empty()
            }
            .map { $0 as Tokens? }
            .replaceError(with: nil)
            .log(to: logger, prefix: "Fetch Refresh") { logger, output in
                logger.log("Fetch Refresh got token: \(output?.token ?? "nil", privacy: .private)")
                logger.log("Fetch Refresh got refresh: \(output?.refresh ?? "nil", privacy: .private)")
            }
            .sink(receiveValue: saveInSubjects)
    }

    func tryUnwrapToken(optToken: String?) throws -> String {
        guard let token = optToken else { throw Error.tokenNil }
        return token
    }

    private func saveInSubjects(tokens: Tokens?) {
        tokenSubject.send(tokens?.token)
        refreshSubject.send(tokens?.refresh)
    }
}

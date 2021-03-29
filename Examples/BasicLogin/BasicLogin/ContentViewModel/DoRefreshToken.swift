//
//  DoRefreshToken.swift
//  BasicLogin
//
//  Created by Andy Bezaire on 21.3.2021.
//

import Foundation
import Combine
import Authorization

extension ContentView.Model {
    /// Use your own call to oath to refresh the token
    func doRefreshTokens(refresh: String?) -> AnyPublisher<Auth.Tokens, Error> {
        Just(Auth.Tokens(token: "NewToken", refresh: "NewRefresh"))
            .tryMap {
                if refresh == nil { throw LoginError.noRefresh }
                return $0
            }
        .eraseToAnyPublisher()
    }
}

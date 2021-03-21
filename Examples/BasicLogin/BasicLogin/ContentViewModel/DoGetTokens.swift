//
//  DoGetTokens.swift
//  BasicLogin
//
//  Created by Andy Bezaire on 20.3.2021.
//

import Authentication
import Combine
import Foundation
import SwiftUI

extension ContentView.Model {
    /// Use your own call to oath to get the token, including possible auth code swap for token
    func doGetTokens() -> AnyPublisher<Auth.Tokens, Error> {
        return Future<Auth.Tokens, Error>() {[weak self] cb in
            self?.callback = Callback(cb)
        }
        .eraseToAnyPublisher()
    }
}

struct Callback: Identifiable {
    let id = UUID()
    let callback: (Result<Auth.Tokens, Error>) -> Void
    init(_ callback: @escaping ((Result<Auth.Tokens, Error>) -> Void)) {
        self.callback = callback
    }
}

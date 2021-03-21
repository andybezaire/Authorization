//
//  DoGetTokens.swift
//  BasicLogin
//
//  Created by Andy Bezaire on 20.3.2021.
//

import Authentication
import Combine
import SwiftUI
import Foundation

extension ContentView.Model {
    var doGetTokens: () -> AnyPublisher<Auth.Tokens, Error> {
        return { [unowned self] in
            return Future<Auth.Tokens, Error>() { cb in
                callback = Callback(cb)
            }
            .eraseToAnyPublisher()
        }
    }
}

struct SignInSheet: View {
    var body: some View {
        Text("hi")
    }
}

struct Callback: Identifiable {
    let id = UUID()
    let callback: ((Result<Auth.Tokens, Error>) -> Void)
    init(_ callback: @escaping ((Result<Auth.Tokens, Error>) -> Void)) {
        self.callback = callback
    }
}

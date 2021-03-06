//
//  SignInOut.swift
//  BasicLogin
//
//  Created by Andy Bezaire on 20.3.2021.
//

import Authorization
import Combine
import Foundation
import UIKit

extension ContentView.Model {
    func signIn() {
        signInOut = auth.signIn()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [unowned self] in
                handle(completion: $0)
            })
    }

    func signOut() {
        signInOut = auth.signOut()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [unowned self] in
                handle(completion: $0)
            })
    }

    private func handle(completion: Subscribers.Completion<Error>) {
        switch completion {
        case .failure(let authError):
            error = authError.localizedDescription
        case .finished:
            error = nil
        }
    }
}

//
//  SignInOut.swift
//  BasicLogin
//
//  Created by Andy Bezaire on 20.3.2021.
//

import Authentication
import Combine
import Foundation
import UIKit

extension ContentView.Model {
    func signIn() {
        signInOut = auth.signIn()
            .sink(receiveCompletion: { [unowned self] in
                handle(completion: $0)
            }, receiveValue: { _ in })
    }

    func signOut() {
        signInOut = auth.signOut()
            .sink(receiveCompletion: { [unowned self] in
                handle(completion: $0)
            }, receiveValue: { _ in })
    }

    private func handle(completion: Subscribers.Completion<Auth.Error>) {
        switch completion {
        case .failure(let authError):
            switch authError {
            case .signInFailed:
                error = "Sign in failed!"
            case .tokenExpired:
                error = "Token expired!"
            case .urlError:
                error = "URL Error!"
            case .signOutFailed:
                error = "Sign out failed!"
            case .unknown:
                error = "Unknown error!!!"
            }
        case .finished:
            error = nil
        }
    }
}

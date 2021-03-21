//
//  ContentView.swift
//  BasicLogin
//
//  Created by Andy Bezaire on 20.3.2021.
//

import Authentication
import SwiftUI

struct ContentView: View {
    @StateObject var model = Model()

    var body: some View {
        NavigationView {
            VStack {
                SignInStatus(status: model.status, isSignedIn: model.isSignedIn)
            }
            .toolbar {
                if model.isSignedIn {
                    Button("Sign out...", action: model.signOut)
                } else {
                    Button("Sign in...", action: model.signIn)
                }
            }
        }
        .sheet(item: $model.callback) {
            LoginSheet(callback: $0)
        }
    }
}

struct SignInStatus: View {
    let status: String
    let isSignedIn: Bool
    var body: some View {
        VStack {
            Image(systemName: profileImage)
                .renderingMode(.original)
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Status: \(status)")
        }
    }

    var profileImage: String {
        isSignedIn ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle.badge.xmark"
    }
}

struct LoginSheet: View {
    @Environment(\.presentationMode) var presentationMode
    let callback: Callback
    var body: some View {
        Form {
            Section(header: Text("Sign in with provider?")) {
                Button("Sign in successfully") {
                    callback.callback(.success(.init(token: "TOKEN", refresh: "REFRESH")))
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Sign in but no refresh") {
                    callback.callback(.success(.init(token: "TOKEN", refresh: nil)))
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Cancel sign in") {
                    callback.callback(.failure(LoginError.cancelled))
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .onDisappear {
            callback.callback(.failure(LoginError.interrupted))
        }
    }
}

enum LoginError: Error {
    case cancelled
    case interrupted
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        LoginSheet(callback: .init { _ in })
    }
}

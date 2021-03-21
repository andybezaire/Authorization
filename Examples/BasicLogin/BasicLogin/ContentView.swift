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

    @State var isNetworkFailures = false
    @State var isTokenExpired = false

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    SignInStatus(status: model.status, isSignedIn: model.isSignedIn)
                    Section(header: Text("Fetch Options")) {
                        Toggle("Network failures", isOn: $isNetworkFailures)
                        Toggle("Token expired", isOn: $isTokenExpired)
                    }
                    FetchStatus(status: nil)
                }
                Text(errorText)
                    .font(.callout)
                    .foregroundColor(.red)
            }
            .toolbar {
                if model.isSignedIn {
                    Button("Sign out...", action: model.signOut)
                } else {
                    Button("Sign in...", action: model.signIn)
                }
            }
            .navigationTitle("Authentication")
        }
        .sheet(item: $model.callback) {
            LoginSheet(callback: $0)
        }
    }

    var errorText: String {
        model.error.map { "Error: \($0)" } ?? " "
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
        .frame(maxWidth: .infinity)
    }

    var profileImage: String {
        isSignedIn ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle.badge.xmark"
    }
}

struct FetchStatus: View {
    let status: String?
    var body: some View {
        VStack {
            Text(fetchStatus)
            Button("Fetch", action: {})
        }
        .frame(maxWidth: .infinity)
    }

    var fetchStatus: String {
        status.map { $0 } ?? " "
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
    case noRefresh
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        LoginSheet(callback: .init { _ in })
    }
}

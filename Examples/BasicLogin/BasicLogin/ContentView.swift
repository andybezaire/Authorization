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
        VStack {
            Text("Status: \(model.status)")
            Button("Sign in...", action: model.signIn)
            Button("Sign out...", action: model.signOut)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

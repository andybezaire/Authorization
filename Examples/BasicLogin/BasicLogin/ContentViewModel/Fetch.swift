//
//  Fetch.swift
//  BasicLogin
//
//  Created by Andy Bezaire on 21.3.2021.
//

import Foundation

extension ContentView.Model {
    func fetch() {
        fetchStatus = "fetching..."
        let url = URL(string: "http://example.com")!
        let request = URLRequest(url: url)

        fetching = auth.fetch(request)
            .sink(receiveCompletion: { [unowned self] completion in
                switch completion {
                case .failure:
                    fetchStatus = "Fetch failed!"
                case .finished:
                    fetchStatus = "Fetch successful."
                }
            }, receiveValue: { [unowned self] _ in
                fetchStatus = "Fetch successful"
            })
    }
}

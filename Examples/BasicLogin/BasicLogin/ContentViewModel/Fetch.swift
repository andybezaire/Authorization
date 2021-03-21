//
//  Fetch.swift
//  BasicLogin
//
//  Created by Andy Bezaire on 21.3.2021.
//

import Foundation
import Mocker

extension ContentView.Model {
    func fetch() {
        fetchStatus = "fetching..."
        let url = URL(string: "http://example.com")!
        let request = URLRequest(url: url)

        Mock(sequentialMocks: [
            Mock(url: url, dataType: .json, statusCode: 403, data: [.get: Data()]),
            Mock(url: url, dataType: .json, statusCode: 200, data: [.get: Data()]),
        ])?.register()

        fetching = auth.fetch(request)
            .receive(on: RunLoop.main)
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

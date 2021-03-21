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

        if isTokenExpired {
            Mock(sequentialMocks: [
                Mock(url: url, dataType: .json, statusCode: 403, data: [.get: Data()]),
                Mock(url: url, dataType: .json, statusCode: 200, data: [.get: Data()]),
            ])?.register()
        } else {
            Mock(url: url, dataType: .json, statusCode: 200, data: [.get: Data()]).register()
        }

        if isNetworkFailures {
            Mock(url: url, dataType: .json, statusCode: 999, data: [.get: Data()], requestError: URLError(.badURL)).register()
        }

        fetching = auth.fetch(request)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [unowned self] completion in
                switch completion {
                case .failure(let fetchError):
                    fetchStatus = "Fetch failed!"
                    error = fetchError.localizedDescription
                case .finished:
                    fetchStatus = "Fetch successful."
                    error = nil
                }
            }, receiveValue: { [unowned self] _ in
                fetchStatus = "Fetch successful"
            })
    }
}

//
//  Utils.swift
//  BasicLogin
//
//  Created by Andy Bezaire on 21.3.2021.
//

import Foundation
import Mocker

/// allows mocks to change per request from an array of mocks
extension Mock {
    mutating func appendCompletion(_ completion: @escaping () -> Void) {
        if let currentCompletion = self.completion {
            self.completion = { currentCompletion() ; completion() }
        } else {
            self.completion = completion
        }
    }
    
    init?(sequentialMocks: [Mock]) {
        let optMock: Mock? = sequentialMocks.reversed().reduce(nil) { acc, mock in
            var modifiedMock = mock
            if let nextMock = acc {
                modifiedMock.appendCompletion {
                    nextMock.register()
                }
            }
            return modifiedMock
        }
        guard let mock = optMock else { return nil }
        self = mock
    }
}

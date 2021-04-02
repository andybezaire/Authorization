//
//  Utils.swift
//  
//
//  Created by Andy Bezaire on 2.4.2021.
//

import Foundation
import Combine

public extension Publisher where Output == Never {
    func sink(receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void)) -> AnyCancellable {
        self.sink(receiveCompletion: receiveCompletion, receiveValue: { _ in })
    }
}

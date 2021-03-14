//
//  MockTokenValueSubject.swift
//
//
//  Created by Andy Bezaire on 13.3.2021.
//

import Combine
import Authentication
import Foundation

public class MockTokenValueSubject<Output, Failure>: TokenValueSubject<Output, Failure> where Failure: Error {
    override open func send(_ value: Output) {
        values.append(value)
        super.send(value)
    }

    open override func send(subscription: Subscription) {
        subscriptionCallCount += 1
        super.send(subscription: subscription)
    }

    open override func send(completion: Subscribers.Completion<Failure>) {
        completions.append(completion)
        super.send(completion: completion)
    }
    open override func receive<S>(subscriber: S) where Output == S.Input, Failure == S.Failure, S : Subscriber {
        recieveCallCount += 1
        super.receive(subscriber: subscriber)
    }

    internal(set) public var values = [Output]()
    internal(set) public var subscriptionCallCount = 0
    internal(set) public var completions = [Subscribers.Completion<Failure>]()
    internal(set) public var recieveCallCount = 0

    public var valueCallCount: Int { values.count }
    public var completionCallCount: Int { completions.count }
}

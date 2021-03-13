//
//  MockSubject.swift
//
//
//  Created by Andy Bezaire on 13.3.2021.
//

import Combine
import Foundation

public class MockSubject<Output, Failure>: Subject where Failure: Error {
    let subject: CurrentValueSubject<Output, Failure>

    public init(_ initialValue: Output) {
        self.subject = CurrentValueSubject<Output, Failure>(initialValue)
    }

    public func send(_ value: Output) {
        values.append(value)
        subject.send(value)
    }

    public func send(subscription: Subscription) {
        subscriptionCallCount += 1
        subject.send(subscription: subscription)
    }

    public func send(completion: Subscribers.Completion<Failure>) {
        completions.append(completion)
        subject.send(completion: completion)
    }

    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, S.Input == Output {
        recieveCallCount += 1
        subject.receive(subscriber: subscriber)
    }

    internal(set) public var values = [Output]()
    internal(set) public var subscriptionCallCount = 0
    internal(set) public var completions = [Subscribers.Completion<Failure>]()
    internal(set) public var recieveCallCount = 0

    public var valueCallCount: Int { values.count }
    public var completionCallCount: Int { completions.count }
}

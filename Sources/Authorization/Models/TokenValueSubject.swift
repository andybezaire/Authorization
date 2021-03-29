//
//  TokenValueSubject.swift
//
//
//  Created by Andy Bezaire on 13.3.2021.
//

import Combine
import Foundation

/// This is a wrapper for `CurrentValueSubject` as that class is marked final. This can be inherited for mocks.
open class TokenValueSubject<Output, Failure>: Subject where Failure: Error {
    let subject: CurrentValueSubject<Output, Failure>

    public init(_ initialValue: Output) {
        self.subject = CurrentValueSubject<Output, Failure>(initialValue)
    }

    open func send(_ value: Output) {
        subject.send(value)
    }

    open func send(subscription: Subscription) {
        subject.send(subscription: subscription)
    }

    open func send(completion: Subscribers.Completion<Failure>) {
        subject.send(completion: completion)
    }

    open func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, S.Input == Output {
        subject.receive(subscriber: subscriber)
    }

    public var value: Output {
        subject.value
    }
}

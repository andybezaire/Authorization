//
//  MockFunctions.swift
//
//
//  Created by Andy Bezaire on 13.3.2021.
//

import Foundation
import XCTest

/// Class for mocking a function with no inputs
public class MockFunction0<Output> {
    public typealias FunctionSignature = (() -> Output)
    let output: FunctionSignature?
    var outputs: [FunctionSignature]
    internal(set) public var callCount = 0

    /// Set the output for the function
    /// - Parameter output: this is output of the function to be mocked
    public init(output: @escaping FunctionSignature) {
        self.outputs = []
        self.output = output
    }

    /// Set the outputs for the function
    /// - Parameter outputs: these are secquentially used as output of the function starting from the first element
    public init(outputs: [FunctionSignature]) {
        self.output = nil
        self.outputs = outputs
    }

    /// pass  this as the function you would like to mock
    /// - Returns: either the single output or the first element of the output array and removing it
    public func function() -> Output {
        callCount += 1
        if let singleOutput = output {
            return singleOutput()
        } else {
            XCTAssertFalse(outputs.isEmpty, "ran out of outputs from function")
            return outputs.removeFirst()()
        }
    }

    /// Shorthand to access the function by calling the object
    /// - Returns: the function to be mocked
    public func callAsFunction() -> FunctionSignature { function }
}

/// Class for mocking a function with one inputs
public class MockFunction1<Input, Output> {
    public typealias FunctionSignature = ((Input) -> Output)
    internal(set) public var inputs = [Input]()
    let output: FunctionSignature?
    var outputs: [FunctionSignature]
    public var callCount: Int { inputs.count }

    /// Set the output for the function, given an input
    /// - Parameter outputs: these are secquentially used as output of the function starting from the first element
    public init(output: @escaping FunctionSignature) {
        self.outputs = []
        self.output = output
    }

    /// Set an array of sequential outputs for the function, , given an input
    /// - Parameter outputs: these are secquentially used as output of the function starting from the first element
    public init(outputs: [FunctionSignature]) {
        self.output = nil
        self.outputs = outputs
    }

    /// pass  this as the function you would like to mock
    /// - Returns: either the single output or the first element of the output array and removing it
    public func function(input: Input) -> Output {
        inputs.append(input)
        if let singleOutput = output {
            return singleOutput(input)
        } else {
            XCTAssertFalse(outputs.isEmpty, "ran out of outputs from function")
            return outputs.removeFirst()(input)
        }
    }

    /// Shorthand to access the function by calling the object
    /// - Returns: the function to be mocked
    public func callAsFunction() -> FunctionSignature { function }
}

/// Class for mocking a function with two inputs
public class MockFunction2<InputA, InputB, Output> {
    public typealias FunctionSignature = ((InputA, InputB) -> Output)
    internal(set) public var inputs = [(InputA, InputB)]()
    let output: FunctionSignature?
    var outputs: [FunctionSignature]
    public var callCount: Int { inputs.count }

    /// Set the output for the function, given an input
    /// - Parameter output: the closure performed to generate the output on calling
    public init(output: @escaping FunctionSignature) {
        self.outputs = []
        self.output = output
    }

    /// Set an array of sequential outputs for the function, , given an input
    /// - Parameter outputs: these are secquentially used as output of the function starting from the first element
    public init(outputs: [FunctionSignature]) {
        self.output = nil
        self.outputs = outputs
    }

    /// pass  this as the function you would like to mock
    /// - Returns: either the single output or the first element of the output array and removing it
    public func function(inputA: InputA, inputB: InputB) -> Output {
        inputs.append((inputA, inputB))
        if let singleOutput = output {
            return singleOutput(inputA, inputB)
        } else {
            XCTAssertFalse(outputs.isEmpty, "ran out of outputs from function")
            return outputs.removeFirst()(inputA, inputB)
        }
    }

    /// Shorthand to access the function by calling the object
    /// - Returns: the function to be mocked
    public func callAsFunction() -> FunctionSignature { function }
}

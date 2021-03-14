import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SignInTests.allTests),
        testCase(FetchTests.allTests),
        testCase(MultipleFetchTests.allTests),
        testCase(UseCaseTests.allTests),
    ]
}
#endif

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(FetchTests.allTests),
        testCase(MultipleFetchTests.allTests),
        testCase(SignInTests.allTests),
        testCase(StatusTests.allTests),
        testCase(UseCaseTests.allTests),
    ]
}
#endif

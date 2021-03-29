import XCTest

import AuthorizationTests

var tests = [XCTestCaseEntry]()
tests += AuthenticationTests.allTests()
XCTMain(tests)

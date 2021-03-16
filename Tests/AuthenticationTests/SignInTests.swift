//
//  SignInTests.swift
//
//
//  Created by Andy Bezaire on 14.3.2021.
//

@testable import Authentication
import XCTest

final class SignInTests: AuthenticationTests {
    func testSignInSuccessful() {
        let signInFinished = XCTestExpectation(description: "Sign in finished")

        let auth = Auth(
            doGetTokens: getTokensSuccess(),
            doRefreshToken: refreshTokenUnused(),
            signRequest: signRequestUnused(),
            shouldDoRefreshFor: shouldDoRefreshForUnused(),
            tokenSubject: token,
            refreshSubject: refresh,
            logger: logger
        )

        cancellable = auth.signIn()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break // success
                case .failure:
                    XCTFail("Sign in should succeed")
                }
                signInFinished.fulfill()
            }, receiveValue: { _ in
                XCTFail("Sign in should not receive value")
            })

        wait(for: [signInFinished], timeout: 1)

        XCTAssertEqual(getTokensSuccess.callCount, 1, "should fetch tokens once")
        XCTAssertEqual(token.valueCallCount, 1, "should have gotten value once")
        XCTAssertEqual(token.value, "TOKEN", "should have gotten proper token")
        XCTAssertEqual(refresh.valueCallCount, 1, "should have gotten value once")
        XCTAssertEqual(refresh.value, "REFRESH", "should have gotten proper refresh")
    }

    func testSignInFails() {
        let signInFinished = XCTestExpectation(description: "Sign in finished")

        let auth = Auth(
            doGetTokens: getTokensFail(),
            doRefreshToken: refreshTokenUnused(),
            signRequest: signRequestUnused(),
            shouldDoRefreshFor: shouldDoRefreshForUnused(),
            tokenSubject: token,
            refreshSubject: refresh,
            logger: logger
        )

        cancellable = auth.signIn()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTFail("Sign in should fail")
                case .failure(let error):
                    XCTAssertEqual(error, Auth.Error.signInFailed(TestError.canBeAnyError), "Error sould be signInFailed")
                    signInFinished.fulfill() // success
                }
            }, receiveValue: { _ in
                XCTFail("Sign in should not receive value")
            })

        wait(for: [signInFinished], timeout: 1)

        XCTAssertEqual(getTokensFail.callCount, 1, "should fetch tokens once")
        XCTAssertEqual(token.valueCallCount, 1, "should have gotten value once")
        XCTAssertNil(token.value, "token should have been cleared to nil")
        XCTAssertEqual(refresh.valueCallCount, 1, "should have gotten value once")
        XCTAssertNil(refresh.value, "refresh should have been cleared to nil")
    }

    #if !canImport(ObjectiveC)
    static var allTests: [XCTestCaseEntry] = [
        ("testSignInSuccessful", testSignInSuccessful),
        ("testSignInFails", testSignInFails),
    ]
    #endif
}

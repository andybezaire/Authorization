//
//  StatusTests.swift
//
//
//  Created by Andy Bezaire on 19.3.2021.
//

import Foundation

@testable import Authorization
import Mocker
import XCTest

final class StatusTests: AuthorizationTests {
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

        var statuses = [Auth.Status]()
        statusCancellable = auth.status
            .sink { status in
                statuses.append(status)
            }

        cancellable = auth.signIn()
            .sink(receiveCompletion: { _ in signInFinished.fulfill() })

        wait(for: [signInFinished], timeout: 1)

        let signingInOnce = statuses.filter { $0 == .signingIn }.count
        XCTAssertEqual(signingInOnce, 1, "should have signed in exactly once")
        XCTAssertEqual(statuses.last, .signedIn, "should be signed in")
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

        var statuses = [Auth.Status]()
        statusCancellable = auth.status
            .sink { status in
                statuses.append(status)
            }

        cancellable = auth.signIn()
            .sink(receiveCompletion: { _ in signInFinished.fulfill() })

        wait(for: [signInFinished], timeout: 1)

        let signingInOnce = statuses.filter { $0 == .signingIn }.count
        XCTAssertEqual(signingInOnce, 1, "should have signed in exactly once")
        XCTAssertEqual(statuses.last, .notSignedIn, "should not be signed in")
    }

    func testSignInNoRefresh() {
        let signInFinished = XCTestExpectation(description: "Sign in finished")

        let auth = Auth(
            doGetTokens: getTokensNoRefresh(),
            doRefreshToken: refreshTokenUnused(),
            signRequest: signRequestUnused(),
            shouldDoRefreshFor: shouldDoRefreshForUnused(),
            tokenSubject: token,
            refreshSubject: refresh,
            logger: logger
        )

        var statuses = [Auth.Status]()
        statusCancellable = auth.status
            .sink { status in
                statuses.append(status)
            }

        cancellable = auth.signIn()
            .sink(receiveCompletion: { _ in signInFinished.fulfill() })

        wait(for: [signInFinished], timeout: 1)

        let signingInOnce = statuses.filter { $0 == .signingIn }.count
        XCTAssertEqual(signingInOnce, 1, "should have signed in exactly once")
        XCTAssertEqual(statuses.last, .signedInNoRefresh, "should be signed in no refresh")
    }

    func testFetchRefreshSuccessful() {
        let fetchFinished = XCTestExpectation(description: "Fetch request finished")

        let auth = Auth(
            doGetTokens: getTokensUnused(),
            doRefreshToken: refreshTokenSuccess(),
            signRequest: signRequestPassthrough(),
            shouldDoRefreshFor: shouldDoRefreshForFirstTimeOnly(),
            tokenSubject: validToken,
            refreshSubject: validRefresh,
            logger: logger
        )

        Mock(url: url, dataType: .json, statusCode: 200, data: [.get: Data()])
            .register()

        var statuses = [Auth.Status]()
        statusCancellable = auth.status
            .sink { status in
                statuses.append(status)
            }

        cancellable = auth.fetch(request)
            .sink(receiveCompletion: { _ in fetchFinished.fulfill() }, receiveValue: { _ in })

        wait(for: [fetchFinished], timeout: 1)

        let refreshOnce = statuses.filter { $0 == .refreshingToken }.count
        XCTAssertEqual(refreshOnce, 1, "should have signed in exactly once")
    }

    func testFetchRefreshTokenExpired() {
        let fetchFinished = XCTestExpectation(description: "Fetch request finished")

        let auth = Auth(
            doGetTokens: getTokensUnused(),
            doRefreshToken: refreshTokenFail(),
            signRequest: signRequestPassthrough(),
            shouldDoRefreshFor: shouldDoRefreshForFirstTimeOnly(),
            tokenSubject: validToken,
            refreshSubject: validRefresh,
            logger: logger
        )

        Mock(url: url, dataType: .json, statusCode: 200, data: [.get: Data()])
            .register()

        var statuses = [Auth.Status]()
        statusCancellable = auth.status
            .sink { status in
                statuses.append(status)
            }

        cancellable = auth.fetch(request)
            .sink(receiveCompletion: { _ in fetchFinished.fulfill() }, receiveValue: { _ in })

        wait(for: [fetchFinished], timeout: 1)

        let refreshOnce = statuses.filter { $0 == .refreshingToken }.count
        XCTAssertEqual(refreshOnce, 1, "should have tried to refresh exactly once")
        XCTAssertEqual(statuses.last, .signedInTokenExpired, "should be signed in with expired token")
    }

    func testSignOutSuccessful() {
        let signOutFinished = XCTestExpectation(description: "Sign out finished")

        let auth = Auth(
            doGetTokens: getTokensUnused(),
            doRefreshToken: refreshTokenUnused(),
            signRequest: signRequestUnused(),
            shouldDoRefreshFor: shouldDoRefreshForUnused(),
            tokenSubject: validToken,
            refreshSubject: validRefresh,
            logger: logger
        )
        
        var statuses = [Auth.Status]()
        statusCancellable = auth.status
            .sink { status in
                statuses.append(status)
            }

        cancellable = auth.signOut()
            .sink(receiveCompletion: { _ in signOutFinished.fulfill() })

        wait(for: [signOutFinished], timeout: 1)

        let signOutOnce = statuses.filter { $0 == .signingOut }.count
        XCTAssertEqual(signOutOnce, 1, "should have signed in exactly once")
        XCTAssertEqual(statuses.last, .notSignedIn, "should not be signed in")
    }

    #if !canImport(ObjectiveC)
    static var allTests: [XCTestCaseEntry] = [
        ("testSignInSuccessful", testSignInSuccessful),
        ("testSignInFails", testSignInFails),
        ("testSignInNoRefresh", testSignInNoRefresh),
        ("testFetchRefreshSuccessful", testFetchRefreshSuccessful),
        ("testFetchRefreshTokenExpired", testFetchRefreshTokenExpired),
        ("testSignOutSuccessful", testSignOutSuccessful),
    ]
    #endif
}

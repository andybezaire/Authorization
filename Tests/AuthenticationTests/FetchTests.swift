//
//  FetchTests.swift
//
//
//  Created by Andy Bezaire on 14.3.2021.
//

@testable import Authentication
import Mocker
import XCTest

final class FetchTests: AuthenticationTests {
    func testFetchSuccessful() {
        let fetchFinished = XCTestExpectation(description: "Fetch request finished")

        let auth = Auth(
            doGetTokens: getTokensUnused(),
            doRefreshToken: refreshTokenUnused(),
            signRequest: signRequestPassthrough(),
            shouldDoRefreshFor: shouldDoRefreshForNever(),
            tokenSubject: validToken,
            refreshSubject: refresh,
            logger: logger
        )

        Mock(url: url, dataType: .json, statusCode: 200, data: [.get: Data()])
            .register()

        cancellable = auth.fetch(request)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    fetchFinished.fulfill() // success
                case .failure:
                    XCTFail("Should not fail on finish")
                }
            }, receiveValue: { result in
                let code = (result.response as? HTTPURLResponse)?.statusCode
                XCTAssertNotNil(code, "Response should be HTTPURLResponse")
                XCTAssertEqual(code, 200, "Status code should be 200")
            })

        wait(for: [fetchFinished], timeout: 1)

        XCTAssertEqual(signRequestPassthrough.callCount, 1, "should have signed request once")
        XCTAssertEqual(shouldDoRefreshForNever.callCount, 1, "should have checked to see if we need to refresh token")
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

        cancellable = auth.fetch(request)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    fetchFinished.fulfill() // success
                case .failure:
                    XCTFail("Should not fail on finish")
                }
            }, receiveValue: { result in
                let code = (result.response as? HTTPURLResponse)?.statusCode
                XCTAssertNotNil(code, "Response should be HTTPURLResponse")
                XCTAssertEqual(code, 200, "Status code should be 200")
            })

        wait(for: [fetchFinished], timeout: 1)

        XCTAssertEqual(signRequestPassthrough.callCount, 2, "should have signed request twice, once for the first time getting refresh needed and once for the new request weith the refreshed token")
        XCTAssertEqual(shouldDoRefreshForFirstTimeOnly.callCount, 2, "should have checked to see if we need to refresh token twice, once for the first time getting refresh needed and once for the new request weith the refreshed token")
        XCTAssertEqual(refreshTokenSuccess.callCount, 1, "should have refreshed token")
        XCTAssertEqual(validToken.value, "REFRESH+TOKEN", "token should have gotten the refresh value")
        XCTAssertEqual(validRefresh.value, "REFRESH+REFRESH", "token should have gotten the refresh value")
    }

    func testFetchWhenNotSignedInFails() {
        let requestFinished = XCTestExpectation(description: "Fetch request finished")

        let auth = Auth(
            doGetTokens: getTokensUnused(),
            doRefreshToken: refreshTokenUnused(),
            signRequest: signRequestUnused(),
            shouldDoRefreshFor: shouldDoRefreshForUnused(),
            tokenSubject: token,
            refreshSubject: refresh,
            logger: logger
        )

        cancellable = auth.fetch(request)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTFail("Fetch should complete with error")
                case .failure(let error):
                    XCTAssertEqual(error, Auth.Error.tokenExpired, "Error should be token expired")
                }
                requestFinished.fulfill()
            }, receiveValue: { _ in
                XCTFail("Fetch should not receive value, it should fail with error")
            })

        wait(for: [requestFinished], timeout: 1)
    }

    func testFetchWithExpiredRefreshTokenFails() {
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

        let fetchFinished = XCTestExpectation(description: "Fetch request finished")

        cancellable = auth.fetch(request)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTFail("Should fail with error")
                case .failure(let error):
                    XCTAssertEqual(error, Auth.Error.tokenExpired, "Error should be that token is expired")
                    fetchFinished.fulfill() // success
                }
            }, receiveValue: { _ in
                XCTFail("Should fail with error and not receive a response")
            })

        wait(for: [fetchFinished], timeout: 1)

        XCTAssertEqual(signRequestPassthrough.callCount, 1, "should have signed request once")
        XCTAssertEqual(shouldDoRefreshForFirstTimeOnly.callCount, 1, "should have checked to see if we need to refresh token once")
        XCTAssertEqual(refreshTokenFail.callCount, 1, "should have tried to refresh token")
        XCTAssertEqual(validToken.value, "TOKEN", "should not have reset token on error")
        XCTAssertEqual(validRefresh.value, "REFRESH", "should not have reset refresh on error")
    }

    func testFetchWithSessionFailFails() {
        let auth = Auth(
            doGetTokens: getTokensUnused(),
            doRefreshToken: refreshTokenUnused(),
            signRequest: signRequestPassthrough(),
            shouldDoRefreshFor: shouldDoRefreshForUnused(),
            tokenSubject: validToken,
            refreshSubject: refresh,
            logger: logger
        )

        Mock(url: url, dataType: .json, statusCode: 999, data: [.get: Data()], requestError: URLError(.badURL))
            .register()

        let fetchFinished = XCTestExpectation(description: "Fetch request finished")

        cancellable = auth.fetch(request)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTFail("Should fail with error")
                case .failure(let error):
                    XCTAssertEqual(error, Auth.Error.urlError(URLError(.badURL)), "Error should be from session")
                    fetchFinished.fulfill() // success
                }
            }, receiveValue: { _ in
                XCTFail("Should fail with error and not receive a response")
            })

        wait(for: [fetchFinished], timeout: 1)

        XCTAssertEqual(signRequestPassthrough.callCount, 1, "should have signed request once")
    }

    #if !canImport(ObjectiveC)
    static var allTests: [XCTestCaseEntry] = [
        ("testFetchSuccessful", testFetchSuccessful),
        ("testFetchRefreshSuccessful", testFetchRefreshSuccessful),
        ("testFetchWhenNotSignedInFails", testFetchWhenNotSignedInFails),
        ("testFetchWithExpiredRefreshTokenFails", testFetchWithExpiredRefreshTokenFails),
        ("testFetchWithSessionFailFails", testFetchWithSessionFailFails),
    ]
    #endif
}

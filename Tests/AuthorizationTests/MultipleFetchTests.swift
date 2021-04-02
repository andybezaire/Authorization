//
//  MultipleFetchTests.swift
//
//
//  Created by Andy Bezaire on 14.3.2021.
//

@testable import Authorization
import Mocker
import XCTest

final class MultipleFetchTests: AuthorizationTests {
    func testTwoFetchesSucceessful() {
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

        let firstFetchFinished = XCTestExpectation(description: "First fetch request finished")

        cancellable = auth.fetch(request)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure: XCTFail("Should not fail on first fetch finish")
                case .finished: break // first fetch should succeed
                }
                firstFetchFinished.fulfill()
            }, receiveValue: { _ in })

        wait(for: [firstFetchFinished], timeout: 1)

        let secondFetchFinished = XCTestExpectation(description: "Second fetch request finished")

        cancellable = auth.fetch(request)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure: XCTFail("Should not fail on finish")
                case .finished: secondFetchFinished.fulfill() // success
                }
            }, receiveValue: { result in
                let code = (result.response as? HTTPURLResponse)?.statusCode
                XCTAssertNotNil(code, "Response should be HTTPURLResponse")
                XCTAssertEqual(code, 200, "Status code should be 200")
            })

        wait(for: [secondFetchFinished], timeout: 1)

        XCTAssertEqual(signRequestPassthrough.callCount, 2, "should have signed each request once")
        XCTAssertEqual(shouldDoRefreshForNever.callCount, 2, "should have checked each request to see if we need to refresh token")
    }

    func testTwoFetchRefreshesSuccessful() {
        let auth = Auth(
            doGetTokens: getTokensUnused(),
            doRefreshToken: refreshTokenSuccess(),
            signRequest: signRequestPassthrough(),
            shouldDoRefreshFor: shouldDoRefreshEveryOtherTime(),
            tokenSubject: validToken,
            refreshSubject: validRefresh,
            logger: logger
        )

        Mock(url: url, dataType: .json, statusCode: 200, data: [.get: Data()])
            .register()

        let firstFetchFinished = XCTestExpectation(description: "First fetch request finished")

        cancellable = auth.fetch(request)
            .sink { completion in
                switch completion {
                case .failure: XCTFail("Should not fail on finish")
                case .finished: break // should finish without error
                }
                firstFetchFinished.fulfill()
            } receiveValue: { _ in }

        wait(for: [firstFetchFinished], timeout: 1)

        let secondFetchFinished = XCTestExpectation(description: "Second fetch request finished")

        cancellable = auth.fetch(request)
            .sink { completion in
                switch completion {
                case .finished: secondFetchFinished.fulfill() // success
                case .failure: XCTFail("Should not fail on finish")
                }
            } receiveValue: { result in
                let code = (result.response as? HTTPURLResponse)?.statusCode
                XCTAssertNotNil(code, "Response should be HTTPURLResponse")
                XCTAssertEqual(code, 200, "Status code should be 200")
            }

        wait(for: [secondFetchFinished], timeout: 1)

        XCTAssertEqual(signRequestPassthrough.callCount, 4, "should have signed both requests twice, once for the first time getting refresh needed and once for the new request weith the refreshed token")
        XCTAssertEqual(shouldDoRefreshEveryOtherTime.callCount, 4, "both requests should have checked to see if we need to refresh token twice, once for the first time getting refresh needed and once for the new request weith the refreshed token")
        XCTAssertEqual(refreshTokenSuccess.callCount, 2, "should have refreshed token twice")
        XCTAssertEqual(validToken.value, "REFRESH+REFRESH+TOKEN", "token should have gotten the second refresh value")
        XCTAssertEqual(validRefresh.value, "REFRESH+REFRESH+REFRESH", "token should have gotten the second refresh value")
    }

    func testTwoFailedFetchesBothFail() {
        let auth = Auth(
            doGetTokens: getTokensUnused(),
            doRefreshToken: refreshTokenUnused(),
            signRequest: signRequestUnused(),
            shouldDoRefreshFor: shouldDoRefreshForUnused(),
            tokenSubject: token,
            refreshSubject: refresh,
            logger: logger
        )

        Mock(url: url, dataType: .json, statusCode: 999, data: [.get: Data()], requestError: URLError(.badURL))
            .register()

        let firstFetchFinished = XCTestExpectation(description: "First fetch request finished")

        cancellable = auth.fetch(request)
            .sink { completion in
                switch completion {
                case .failure:
                    break // should complete with error
                case .finished:
                    XCTFail("Fetch should complete with error")
                }
                firstFetchFinished.fulfill()
            } receiveValue: { _ in
                XCTFail("Fetch should not receive value, it should fail with error")
            }

        wait(for: [firstFetchFinished], timeout: 1)

        let secondFetchFinished = XCTestExpectation(description: "Second fetch request finished")

        cancellable = auth.fetch(request)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTAssertEqual(error as? Auth.Error, Auth.Error.tokenNil, "Error should be token nil")
                case .finished:
                    XCTFail("Fetch should complete with error")
                }
                secondFetchFinished.fulfill()
            } receiveValue: { _ in
                XCTFail("Fetch should not receive value, it should fail with error")
            }

        wait(for: [secondFetchFinished], timeout: 1)
    }

    func testTwoSessionFailedFetchesBothFail() {
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

        let firstFetchFinished = XCTestExpectation(description: "First fetch request finished")

        cancellable = auth.fetch(request)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTFail("Should fail with error")
                case .failure(let error):
                    XCTAssertEqual((error as? URLError)?.errorCode, URLError(.badURL).errorCode, "Error should be from session")
                    firstFetchFinished.fulfill() // success
                }
            }, receiveValue: { _ in
                XCTFail("Should fail with error and not receive a response")
            })

        wait(for: [firstFetchFinished], timeout: 1)

        let secondFetchFinished = XCTestExpectation(description: "Second fetch request finished")

        cancellable = auth.fetch(request)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTFail("Should fail with error")
                case .failure(let error):
                    XCTAssertEqual((error as? URLError)?.errorCode, URLError(.badURL).errorCode, "Error should be from session")
                    secondFetchFinished.fulfill() // success
                }
            }, receiveValue: { _ in
                XCTFail("Should fail with error and not receive a response")
            })

        wait(for: [secondFetchFinished], timeout: 1)

        XCTAssertEqual(signRequestPassthrough.callCount, 2, "should have signed each request once")
    }

    #if !canImport(ObjectiveC)
    static var allTests: [XCTestCaseEntry] = [
        ("testTwoFetchesSucceessful", testTwoFetchesSucceessful),
        ("testTwoFetchRefreshesSuccessful", testTwoFetchRefreshesSuccessful),
        ("testTwoFailedFetchesBothFail", testTwoFailedFetchesBothFail),
        ("testTwoSessionFailedFetchesBothFail", testTwoSessionFailedFetchesBothFail),
    ]
    #endif
}

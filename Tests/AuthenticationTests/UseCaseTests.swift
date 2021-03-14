//
//  UseCaseTests.swift
//
//
//  Created by Andy Bezaire on 14.3.2021.
//

@testable import Authentication
import Mocker
import XCTest

final class UseCaseTests: AuthenticationTests {
    func testSignInAndFetchSuccessful() {
        let signInFinished = XCTestExpectation(description: "Sign in finished")

        let auth = Auth(
            doGetTokens: getTokensSuccess(),
            doRefreshToken: refreshTokenUnused()
        )

        cancellable = auth.signIn()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    signInFinished.fulfill() // should finish without error
                case .failure:
                    XCTFail("Sign in should succeed")
                }
            }, receiveValue: { _ in
                XCTFail("Sign in should not receive value")
            })

        wait(for: [signInFinished], timeout: 1)

        Mock(url: url, dataType: .json, statusCode: 200, data: [.get: Data()])
            .register()

        let fetchFinished = XCTestExpectation(description: "Fetch request finished")

        cancellable = auth.fetch(request)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    fetchFinished.fulfill() // should finish without error
                case .failure:
                    XCTFail("Fetch should not fail on finish")
                }
            }, receiveValue: { result in
                let code = (result.response as? HTTPURLResponse)?.statusCode
                XCTAssertNotNil(code, "Response should be HTTPURLResponse")
                XCTAssertEqual(code, 200, "Status code should be 200")
            })

        wait(for: [fetchFinished], timeout: 1)
    }

    func testSignInAndMultipleFetches() {
        let signInFinished = XCTestExpectation(description: "Sign in finished")

        let auth = Auth(
            doGetTokens: getTokensSuccess(),
            doRefreshToken: refreshTokenSuccess()
        )

        cancellable = auth.signIn()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    signInFinished.fulfill() // should finish without error
                case .failure:
                    XCTFail("Sign in should succeed")
                }
            }, receiveValue: { _ in
                XCTFail("Sign in should not receive value")
            })

        wait(for: [signInFinished], timeout: 1)

        // token refresh
        // fail
        // success
        Mock(sequentialMocks: [
            Mock(url: url, dataType: .json, statusCode: 403, data: [.get: Data()]),
            Mock(url: url, dataType: .json, statusCode: 200, data: [.get: Data()]),
            Mock(url: url, dataType: .json, statusCode: 999, data: [.get: Data()], requestError: URLError(.badURL)),
            Mock(url: url, dataType: .json, statusCode: 200, data: [.get: Data()]),

        ])
            .register()

        let fetchWithRefreshFinished = XCTestExpectation(description: "Fetch request with refresh finished")

        cancellable = auth.fetch(request)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    fetchWithRefreshFinished.fulfill() // should finish without error
                case .failure:
                    XCTFail("Fetch should not fail on finish")
                }
            }, receiveValue: { result in
                let code = (result.response as? HTTPURLResponse)?.statusCode
                XCTAssertNotNil(code, "Response should be HTTPURLResponse")
                XCTAssertEqual(code, 200, "Status code should be 200")
            })

        wait(for: [fetchWithRefreshFinished], timeout: 1)

        let fetchWithErrorFinished = XCTestExpectation(description: "Fetch request with error finished")

        cancellable = auth.fetch(request)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTFail("Fetch should finish with error")
                case .failure:
                    fetchWithErrorFinished.fulfill() // should finish with error
                }
            }, receiveValue: { _ in
                XCTFail("Fetch should fail and not receive a value")
            })

        wait(for: [fetchWithErrorFinished], timeout: 1)

        let fetchWithSuccessFinished = XCTestExpectation(description: "Fetch request with success finished")

        cancellable = auth.fetch(request)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    fetchWithSuccessFinished.fulfill() // should finish without error
                case .failure:
                    XCTFail("Fetch should not fail on finish")
                }
            }, receiveValue: { result in
                let code = (result.response as? HTTPURLResponse)?.statusCode
                XCTAssertNotNil(code, "Response should be HTTPURLResponse")
                XCTAssertEqual(code, 200, "Status code should be 200")
            })

        wait(for: [fetchWithSuccessFinished], timeout: 1)
    }

    func testRequestIsSignedWithBearer() {
        let signInFinished = XCTestExpectation(description: "Sign in finished")

        let auth = Auth(
            doGetTokens: getTokensSuccess(),
            doRefreshToken: refreshTokenSuccess()
        )

        cancellable = auth.signIn()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    signInFinished.fulfill() // should finish without error
                case .failure:
                    XCTFail("Sign in should succeed")
                }
            }, receiveValue: { _ in
                XCTFail("Sign in should not receive value")
            })

        wait(for: [signInFinished], timeout: 1)

        let checkedBearerToken = XCTestExpectation(description: "finished checking bearer token")

        var mock = Mock(url: url, dataType: .json, statusCode: 200, data: [.get: Data()])
        mock.onRequest = { request, _ in
            let bearer = request.value(forHTTPHeaderField: "Authorization")
            XCTAssertEqual(bearer, "Bearer TOKEN", "should use bearer token signing")
            checkedBearerToken.fulfill()
        }
        mock.register()

        let fetchFinished = XCTestExpectation(description: "Fetch request finished")

        cancellable = auth.fetch(request)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    fetchFinished.fulfill() // should finish without error
                case .failure:
                    XCTFail("Fetch should not fail on finish")
                }
            }, receiveValue: { result in
                let code = (result.response as? HTTPURLResponse)?.statusCode
                XCTAssertNotNil(code, "Response should be HTTPURLResponse")
                XCTAssertEqual(code, 200, "Status code should be 200")
            })

        wait(for: [fetchFinished, checkedBearerToken], timeout: 1)
    }

    #if !canImport(ObjectiveC)
    static var allTests: [XCTestCaseEntry] = [
        ("testSignInAndFetchSuccessful", testSignInAndFetchSuccessful),
        ("testSignInAndMultipleFetches", testSignInAndMultipleFetches),
        ("testRequestIsSignedWithBearer", testRequestIsSignedWithBearer),
    ]
    #endif
}

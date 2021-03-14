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

    #if !canImport(ObjectiveC)
    static var allTests: [XCTestCaseEntry] = [
        ("testSignInAndFetchSuccessful", testSignInAndFetchSuccessful),
    ]
    #endif
}

@testable import Authentication
import AuthenticationTestUtils
import Combine
import Mocker
import XCTest

final class AuthenticationTests: XCTestCase {
    let url = URL(string: "http://example.com")!
    var request: URLRequest { URLRequest(url: url) }

    var getTokensSuccess: MockFunction0<AnyPublisher<Auth.Tokens, Error>>!

    var refreshTokenSuccess: MockFunction1<String, AnyPublisher<Auth.Tokens, Error>>!

    var signRequestPassthrough: MockFunction2<URLRequest, String, URLRequest>!

    var shouldDoRefreshForAlways: MockFunction1<Auth.URLResult, Bool>!
    var shouldDoRefreshForNever: MockFunction1<Auth.URLResult, Bool>!
    var firstTime = true
    var shouldDoRefreshForFirstTimeOnly: MockFunction1<Auth.URLResult, Bool>!

    var token: MockTokenValueSubject<String?, Never>!
    var validToken: MockTokenValueSubject<String?, Never>!
    var refresh: MockTokenValueSubject<String?, Never>!
    var validRefresh: MockTokenValueSubject<String?, Never>!

    var cancellable: AnyCancellable?

    override func setUp() {
        // set up test objects
        getTokensSuccess = MockFunction0 {
            Just(Auth.Tokens(token: "TOKEN", refresh: "REFRESH"))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        refreshTokenSuccess = MockFunction1 { (refresh: String) in
            Just(Auth.Tokens(token: refresh + "+TOKEN", refresh: refresh + "+REFRESH"))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        signRequestPassthrough = MockFunction2 { (request: URLRequest, _: String) in
            request
        }

        shouldDoRefreshForAlways = MockFunction1 { (_: Auth.URLResult) in true }
        shouldDoRefreshForNever = MockFunction1 { (_: Auth.URLResult) in false }
        firstTime = true
        shouldDoRefreshForFirstTimeOnly = MockFunction1 { [unowned self] (_: Auth.URLResult) in
            if firstTime {
                firstTime = false
                return true
            } else {
                return false
            }
        }

        token = MockTokenValueSubject<String?, Never>(nil)
        validToken = MockTokenValueSubject<String?, Never>("TOKEN")
        refresh = MockTokenValueSubject<String?, Never>(nil)
        validRefresh = MockTokenValueSubject<String?, Never>("REFRESH")
    }

    func testSignIn() {
        let signInFinished = XCTestExpectation(description: "Sign in finished")

        let auth = Auth(
            doGetTokens: getTokensSuccess(),
            doRefreshToken: refreshTokenSuccess(),
            signRequest: signRequestPassthrough(),
            shouldDoRefreshFor: shouldDoRefreshForAlways(),
            tokenSubject: token,
            refreshSubject: refresh
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
        XCTAssertEqual(token.values.first, "TOKEN", "should have gotten proper token")
        XCTAssertEqual(refresh.valueCallCount, 1, "should have gotten value once")
        XCTAssertEqual(refresh.values.first, "REFRESH", "should have gotten proper refresh")
    }

    func testFetchSuccesful() {
        let fetchFinished = XCTestExpectation(description: "Fetch request finished")

        let auth = Auth(
            doGetTokens: getTokensSuccess(),
            doRefreshToken: refreshTokenSuccess(),
            signRequest: signRequestPassthrough(),
            shouldDoRefreshFor: shouldDoRefreshForNever(),
            tokenSubject: validToken,
            refreshSubject: refresh
        )

        Mock(url: url, dataType: .json, statusCode: 200, data: [.get: Data()])
            .register()

        cancellable = auth.fetch(request)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    fetchFinished.fulfill() // success
                case .failure(_):
                    XCTFail("Should not fail on finish")
                }
            }, receiveValue: { (result) in
                let code = (result.response as? HTTPURLResponse)?.statusCode
                XCTAssertNotNil(code, "Response should be HTTPURLResponse")
                XCTAssertEqual(code, 200, "Status code should be 200")
            })

        wait(for: [fetchFinished], timeout: 1)

        XCTAssertEqual(signRequestPassthrough.callCount, 1, "should have signed request once")
        XCTAssertEqual(shouldDoRefreshForNever.callCount, 1, "should have checked to see if we need to refresh token")
    }

    func testFetchWhenNotSignedInFails() {
        let requestFinished = XCTestExpectation(description: "Fetch request finished")

        let auth = Auth(
            doGetTokens: getTokensSuccess(),
            doRefreshToken: refreshTokenSuccess(),
            signRequest: signRequestPassthrough(),
            shouldDoRefreshFor: shouldDoRefreshForAlways(),
            tokenSubject: token,
            refreshSubject: refresh
        )

        Mock(url: url, dataType: .json, statusCode: 999, data: [.get: Data()], requestError: URLError(.badURL))
            .register()

        cancellable = auth.fetch(request)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    XCTFail("Fetch should complete with error")
                case .failure(let error):
                    XCTAssertEqual(error, Auth.Error.tokenExpired, "Error should be token expired")
                }
                requestFinished.fulfill()
            }, receiveValue: { (value) in
                XCTFail("Fetch should not receive value, it should fail with error")
            })

        wait(for: [requestFinished], timeout: 1)
    }

    func testFetchRefreshSuccesful() {
        let fetchFinished = XCTestExpectation(description: "Fetch request finished")

        let auth = Auth(
            doGetTokens: getTokensSuccess(),
            doRefreshToken: refreshTokenSuccess(),
            signRequest: signRequestPassthrough(),
            shouldDoRefreshFor: shouldDoRefreshForFirstTimeOnly(),
            tokenSubject: validToken,
            refreshSubject: validRefresh
        )

        Mock(url: url, dataType: .json, statusCode: 200, data: [.get: Data()])
            .register()

        cancellable = auth.fetch(request)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    fetchFinished.fulfill() // success
                case .failure(_):
                    XCTFail("Should not fail on finish")
                }
            }, receiveValue: { (result) in
                let code = (result.response as? HTTPURLResponse)?.statusCode
                XCTAssertNotNil(code, "Response should be HTTPURLResponse")
                XCTAssertEqual(code, 200, "Status code should be 200")
            })

        wait(for: [fetchFinished], timeout: 1)

        XCTAssertEqual(signRequestPassthrough.callCount, 2, "should have signed request twice, once for the first time getting refresh needed and once for the new request weith the refreshed token")
        XCTAssertEqual(shouldDoRefreshForFirstTimeOnly.callCount, 2, "should have checked to see if we need to refresh token twice, once for the first time getting refresh needed and once for the new request weith the refreshed token")
        XCTAssertEqual(refreshTokenSuccess.callCount, 1, "should have refresed token")
        XCTAssertEqual(validToken.values.first, "REFRESH+TOKEN", "token should have gotten the refresh value")
        XCTAssertEqual(validRefresh.values.first, "REFRESH+REFRESH", "token should have gotten the refresh value")
    }
//    func testRefreshAttemptForExpired() {
//        let requestFinished = XCTestExpectation(description: "Fetch request finished")
//
//        let auth = Auth(doGetTokens: validTokens, doRefreshToken: errorRefresh)
//
//        let url = URL(string: "http://example.com")!
//        let request = URLRequest(url: url)
//
//        Mock(url: url, dataType: .json, statusCode: 403, data: [.get: Data()])
//            .register()
//
//        doSignIn = auth.signIn()
//            .print("sign in", to: logger)
//            .sink(receiveCompletion: { (completion) in
//                switch completion {
//                case .failure(_):
//                    XCTFail("Should not fail on sign in")
//                case .finished:
//                    self.doFetch = auth.fetch(request)
//                        .print("fetch", to: self.logger)
//                        .sink(receiveCompletion: { (completion) in
//                            switch completion {
//                            case .finished:
//                                XCTFail("Fetch should complete with error")
//                            case .failure(let error):
//                                XCTAssertEqual(error, Auth.Error.tokenExpired, "Error should be token expired")
//                            }
//                            requestFinished.fulfill()
//                        }, receiveValue: { (result) in
//                            XCTFail("Fetch should not receive value, it should fail with error")
//                        })
//                }
//            }, receiveValue: { (_) in
//                XCTFail("Should finish without sending value")
//            })
//
//        wait(for: [requestFinished], timeout: 1)
//    }

    static var allTests = [
        ("testSignIn", testSignIn),
        ("testFetchSuccesful", testFetchSuccesful),
        ("testFetchWhenNotSignedInFails", testFetchWhenNotSignedInFails),
    ]
}

extension Auth.Error: Equatable {
    public static func == (lhs: Auth.Error, rhs: Auth.Error) -> Bool {
        switch (lhs, rhs) {
        case (.signInFailed(_), .signInFailed(_)):
            return true
        case (.tokenExpired, .tokenExpired):
            return true
        case (.unknown, .unknown):
            return true
        case (.urlError(_), .urlError(_)):
            return true
        default:
            return false
        }
    }
}

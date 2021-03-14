@testable import Authentication
import AuthenticationTestUtils
import Combine
import Mocker
import XCTest

final class AuthenticationTests: XCTestCase {
    let url = URL(string: "http://example.com")!
    var request: URLRequest { URLRequest(url: url) }

    var getTokensSuccess: MockFunction0<AnyPublisher<Auth.Tokens, Error>>!
    var getTokensFail: MockFunction0<AnyPublisher<Auth.Tokens, Error>>!
    var getTokensUnused: MockFunction0<AnyPublisher<Auth.Tokens, Error>>!

    var refreshTokenSuccess: MockFunction1<String, AnyPublisher<Auth.Tokens, Error>>!
    var refreshTokenFail: MockFunction1<String, AnyPublisher<Auth.Tokens, Error>>!
    var refreshTokenUnused: MockFunction1<String, AnyPublisher<Auth.Tokens, Error>>!

    var signRequestPassthrough: MockFunction2<URLRequest, String, URLRequest>!
    var signRequestUnused: MockFunction2<URLRequest, String, URLRequest>!

    var shouldDoRefreshForAlways: MockFunction1<Auth.URLResult, Bool>!
    var shouldDoRefreshForNever: MockFunction1<Auth.URLResult, Bool>!
    var firstTime = true
    var shouldDoRefreshForFirstTimeOnly: MockFunction1<Auth.URLResult, Bool>!
    var shouldDoRefresh = true
    var shouldDoRefreshEveryOtherTime: MockFunction1<Auth.URLResult, Bool>!
    var shouldDoRefreshForUnused: MockFunction1<Auth.URLResult, Bool>!

    var token: MockTokenValueSubject<String?, Never>!
    var validToken: MockTokenValueSubject<String?, Never>!
    var refresh: MockTokenValueSubject<String?, Never>!
    var validRefresh: MockTokenValueSubject<String?, Never>!

    var cancellable: AnyCancellable?

    override func setUp() {
        // MARK: - doGetTokens mocks
        getTokensSuccess = MockFunction0 {
            Just(Auth.Tokens(token: "TOKEN", refresh: "REFRESH"))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        getTokensFail = MockFunction0 {
            Fail(error: TestError.fail)
                .eraseToAnyPublisher()
        }

        getTokensUnused = MockFunction0 {
            XCTFail("doGetTokens should not be called")
            return Empty().eraseToAnyPublisher()
        }

        // MARK: - doRefreshToken mocks
        refreshTokenSuccess = MockFunction1 { (refresh: String) in
            Just(Auth.Tokens(token: refresh + "+TOKEN", refresh: refresh + "+REFRESH"))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        refreshTokenFail = MockFunction1 { (_: String) in
            Fail(error: TestError.fail)
                .eraseToAnyPublisher()
        }

        refreshTokenUnused = MockFunction1 { (_: String) in
            XCTFail("doRefreshToken should not be called")
            return Empty().eraseToAnyPublisher()
        }

        // MARK: - signRequest: mocks
        signRequestPassthrough = MockFunction2 { (request: URLRequest, _: String) in
            request
        }

        signRequestUnused = MockFunction2 { (request: URLRequest, _: String) in
            XCTFail("signRequest should not be called")
            return URLRequest(url: URL(string: "www.example.com/empty")!)
        }

        // MARK: - shouldDoRefreshFor mocks
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

        shouldDoRefresh = true
        shouldDoRefreshEveryOtherTime = MockFunction1 { [unowned self] (_: Auth.URLResult) in
            defer { shouldDoRefresh.toggle() }
            return shouldDoRefresh
        }

        shouldDoRefreshForUnused = MockFunction1 { (_: Auth.URLResult) in
            XCTFail("shouldDoRefreshFor should not be called")
            return false
        }

        // MARK: - tokenSubject mocks
        token = MockTokenValueSubject<String?, Never>(nil)
        validToken = MockTokenValueSubject<String?, Never>("TOKEN")

        // MARK: - refreshSubject mocks
        refresh = MockTokenValueSubject<String?, Never>(nil)
        validRefresh = MockTokenValueSubject<String?, Never>("REFRESH")
    }

    func testSignInSuccessful() {
        let signInFinished = XCTestExpectation(description: "Sign in finished")

        let auth = Auth(
            doGetTokens: getTokensSuccess(),
            doRefreshToken: refreshTokenUnused(),
            signRequest: signRequestUnused(),
            shouldDoRefreshFor: shouldDoRefreshForUnused(),
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
        XCTAssertEqual(token.value, "TOKEN", "should have gotten proper token")
        XCTAssertEqual(refresh.valueCallCount, 1, "should have gotten value once")
        XCTAssertEqual(refresh.value, "REFRESH", "should have gotten proper refresh")
    }

    func testFetchSuccessful() {
        let fetchFinished = XCTestExpectation(description: "Fetch request finished")

        let auth = Auth(
            doGetTokens: getTokensUnused(),
            doRefreshToken: refreshTokenUnused(),
            signRequest: signRequestPassthrough(),
            shouldDoRefreshFor: shouldDoRefreshForNever(),
            tokenSubject: validToken,
            refreshSubject: refresh
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

    func testFetchWhenNotSignedInFails() {
        let requestFinished = XCTestExpectation(description: "Fetch request finished")

        let auth = Auth(
            doGetTokens: getTokensUnused(),
            doRefreshToken: refreshTokenUnused(),
            signRequest: signRequestUnused(),
            shouldDoRefreshFor: shouldDoRefreshForUnused(),
            tokenSubject: token,
            refreshSubject: refresh
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

    func testFetchRefreshSuccessful() {
        let fetchFinished = XCTestExpectation(description: "Fetch request finished")

        let auth = Auth(
            doGetTokens: getTokensUnused(),
            doRefreshToken: refreshTokenSuccess(),
            signRequest: signRequestPassthrough(),
            shouldDoRefreshFor: shouldDoRefreshForFirstTimeOnly(),
            tokenSubject: validToken,
            refreshSubject: validRefresh
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

    func testFetchWithExpiredRefreshTokenFails() {
        let fetchFinished = XCTestExpectation(description: "Fetch request finished")

        let auth = Auth(
            doGetTokens: getTokensUnused(),
            doRefreshToken: refreshTokenFail(),
            signRequest: signRequestPassthrough(),
            shouldDoRefreshFor: shouldDoRefreshForFirstTimeOnly(),
            tokenSubject: validToken,
            refreshSubject: validRefresh
        )

        Mock(url: url, dataType: .json, statusCode: 200, data: [.get: Data()])
            .register()

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
        XCTAssertNil(validToken.value, "should have reset token to nil on error")
        XCTAssertNil(validToken.value, "should have reset refresh to nil on error")
    }

    func testSignInFails() {
        let signInFinished = XCTestExpectation(description: "Sign in finished")

        let auth = Auth(
            doGetTokens: getTokensFail(),
            doRefreshToken: refreshTokenUnused(),
            signRequest: signRequestUnused(),
            shouldDoRefreshFor: shouldDoRefreshForUnused(),
            tokenSubject: token,
            refreshSubject: refresh
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

    func testTwoFetchesSucceessful() {
        let auth = Auth(
            doGetTokens: getTokensUnused(),
            doRefreshToken: refreshTokenUnused(),
            signRequest: signRequestPassthrough(),
            shouldDoRefreshFor: shouldDoRefreshForNever(),
            tokenSubject: validToken,
            refreshSubject: refresh
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
            refreshSubject: validRefresh
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
            refreshSubject: refresh
        )

        Mock(url: url, dataType: .json, statusCode: 999, data: [.get: Data()], requestError: URLError(.badURL))
            .register()

        let firstFetchFinished = XCTestExpectation(description: "First fetch request finished")

        cancellable = auth.fetch(request)
            .sink { completion in
                switch completion {
                case .failure(_):
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
                    XCTAssertEqual(error, Auth.Error.tokenExpired, "Error should be token expired")
                case .finished:
                    XCTFail("Fetch should complete with error")
                }
                secondFetchFinished.fulfill()
            } receiveValue: { _ in
                XCTFail("Fetch should not receive value, it should fail with error")
            }

        wait(for: [secondFetchFinished], timeout: 1)
    }

    static var allTests = [
        ("testSignInSuccessful", testSignInSuccessful),
        ("testFetchSuccessful", testFetchSuccessful),
        ("testFetchWhenNotSignedInFails", testFetchWhenNotSignedInFails),
        ("testFetchRefreshSuccessful", testFetchRefreshSuccessful),
        ("testFetchWithExpiredRefreshTokenFails", testFetchWithExpiredRefreshTokenFails),
        ("testSignInFails", testSignInFails),
        ("testTwoFetchesSucceessful", testTwoFetchesSucceessful),
        ("testTwoFetchRefreshesSuccessful", testTwoFetchRefreshesSuccessful),
        ("testTwoFailedFetchesBothFail", testTwoFailedFetchesBothFail),
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

enum TestError: Error {
    case fail, canBeAnyError
}

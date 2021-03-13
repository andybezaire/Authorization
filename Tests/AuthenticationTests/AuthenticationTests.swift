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

    var refreshTokenSuccess: MockFunction1<String, AnyPublisher<Auth.Tokens, Error>>!
    var refreshTokenFail: MockFunction1<String, AnyPublisher<Auth.Tokens, Error>>!

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
        getTokensFail = MockFunction0 {
            Fail(error: TestError.fail)
                .eraseToAnyPublisher()
        }

        refreshTokenSuccess = MockFunction1 { (refresh: String) in
            Just(Auth.Tokens(token: refresh + "+TOKEN", refresh: refresh + "+REFRESH"))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        refreshTokenFail = MockFunction1 { (_: String) in
            Fail(error: TestError.fail)
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

    func testSignInSuccessful() {
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
        XCTAssertEqual(token.value, "TOKEN", "should have gotten proper token")
        XCTAssertEqual(refresh.valueCallCount, 1, "should have gotten value once")
        XCTAssertEqual(refresh.value, "REFRESH", "should have gotten proper refresh")
    }

    func testFetchSuccessful() {
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
            doGetTokens: getTokensSuccess(),
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

    static var allTests = [
        ("testSignInSuccessful", testSignInSuccessful),
        ("testFetchSuccessful", testFetchSuccessful),
        ("testFetchWhenNotSignedInFails", testFetchWhenNotSignedInFails),
        ("testFetchRefreshSuccessful", testFetchRefreshSuccessful),
        ("testFetchWithExpiredRefreshTokenFails", testFetchWithExpiredRefreshTokenFails),
        ("testSignInFails", testSignInFails),
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

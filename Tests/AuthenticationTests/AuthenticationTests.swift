@testable import Authentication
import AuthenticationTestUtils
import Combine
import Mocker
import XCTest

final class AuthenticationTests: XCTestCase {

    var getTokensSuccess: MockFunction0<AnyPublisher<Auth.Tokens, Error>>!

    var refreshTokenSuccess: MockFunction1<String, AnyPublisher<Auth.Tokens, Error>>!

    var signRequestPassthrough: MockFunction2<URLRequest, String, URLRequest>!

    var shouldDoRefreshForAlways: MockFunction1<Auth.URLResult, Bool>!
    var shouldDoRefreshForNever: MockFunction1<Auth.URLResult, Bool>!

    var token: MockSubject<String?, Never>!
    var validToken: MockSubject<String?, Never>!
    var refresh: MockSubject<String?, Never>!
    var validRefresh: MockSubject<String?, Never>!

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

        token = MockSubject<String?, Never>(nil)
        validToken = MockSubject<String?, Never>("TOKEN")
        refresh = MockSubject<String?, Never>(nil)
        validRefresh = MockSubject<String?, Never>("REFRESH")
    }

    func testSignIn() {
        let signInFinished = XCTestExpectation(description: "Sign in finished")

        let auth = Auth(
            doGetTokens: getTokensSuccess(),
            doRefreshToken: refreshTokenSuccess(),
            signRequest: signRequestPassthrough(),
            shouldDoRefreshFor: shouldDoRefreshForAlways(),
            tokenSubject: token.eraseToAnySubject(),
            refreshSubject: refresh.eraseToAnySubject()
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
            tokenSubject: validToken.eraseToAnySubject(),
            refreshSubject: refresh.eraseToAnySubject()
        )

        let url = URL(string: "http://example.com")!
        let request = URLRequest(url: url)

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

    func testFetchWhenNotSignedIn() {
        let requestFinished = XCTestExpectation(description: "Fetch request finished")

        let auth = Auth(
            doGetTokens: getTokensSuccess(),
            doRefreshToken: refreshTokenSuccess(),
            signRequest: signRequestPassthrough(),
            shouldDoRefreshFor: shouldDoRefreshForAlways(),
            tokenSubject: token.eraseToAnySubject(),
            refreshSubject: refresh.eraseToAnySubject()
        )

        let url = URL(string: "http://example.com")!
        let request = URLRequest(url: url)

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
        ("testFetchWhenNotSignedIn", testFetchWhenNotSignedIn),
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

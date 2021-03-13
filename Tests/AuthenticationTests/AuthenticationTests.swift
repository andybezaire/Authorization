@testable import Authentication
import AuthenticationTestUtils
import Combine
import XCTest

final class AuthenticationTests: XCTestCase {

    var getTokensSuccess: MockFunction0<AnyPublisher<Auth.Tokens, Error>>!

    var refreshTokenSuccess: MockFunction1<String, AnyPublisher<Auth.Tokens, Error>>!

    var token: MockSubject<String?, Never>!
    var refresh: MockSubject<String?, Never>!

    var signRequestPassthrough: MockFunction2<URLRequest, String, URLRequest>!

    var shouldDoRefreshForAlways: MockFunction1<Auth.URLResult, Bool>!

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

        shouldDoRefreshForAlways = MockFunction1 { (_: Auth.URLResult) in
            true
        }

        token = MockSubject<String?, Never>(nil)
        refresh = MockSubject<String?, Never>(nil)
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

    static var allTests = [
        ("testSignIn", testSignIn),
    ]
}

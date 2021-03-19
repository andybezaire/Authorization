@testable import Authentication
import AuthenticationTestUtils
import Combine
import os.log
import XCTest

class AuthenticationTests: XCTestCase {
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

    let logger = Logger(subsystem: "com.example.authentication", category: "AuthenticationTests")

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

        signRequestUnused = MockFunction2 { (_: URLRequest, _: String) in
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

    override func tearDown() {
        cancellable = nil
    }
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

import Mocker
/// allows mocks to change per request from an array of mocks
extension Mock {
    init(sequentialMocks: [Mock]) {
        let mock: Mock? = sequentialMocks.reversed().reduce(nil) { acc, mock in
            var modifiedMock = mock
            if let nextMock = acc {
                modifiedMock.completion = {
                    nextMock.register()
                }
            }
            return modifiedMock
        }
        self = mock!
    }
}

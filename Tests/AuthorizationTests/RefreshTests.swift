//
//  RefreshTests.swift
//  
//
//  Created by Andy on 4.4.2021.
//

@testable import Authorization
import Mocker
import XCTest

final class RefreshTests: AuthorizationTests {
    func testRefreshSuccessful() {
        let wait100MS = XCTestExpectation(description: "Wait 100 ms finished")

        let auth = Auth(
            doGetTokens: getTokensUnused(),
            doRefreshToken: refreshTokenSuccess(),
            signRequest: signRequestUnused(),
            shouldDoRefreshFor: shouldDoRefreshForUnused(),
            tokenSubject: validToken,
            refreshSubject: validRefresh,
            logger: logger
        )

        var statuses = [Auth.Status]()
        statusCancellable = auth.status
            .sink { status in
                statuses.append(status)
            }
        
        auth.forceTokenRefresh()
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            wait100MS.fulfill()
        }
        wait(for: [wait100MS], timeout: 1)
        
        let refreshingTokenOnce = statuses.filter { $0 == .refreshingToken }.count
        XCTAssertEqual(refreshingTokenOnce, 1, "should have refreshed token exactly once")
        XCTAssertEqual(statuses.last, .signedIn, "should be signed in")

        XCTAssertEqual(refreshTokenSuccess.callCount, 1, "should have refreshed once")
        XCTAssertEqual(validToken.value, "REFRESH+TOKEN", "token should have gotten the refresh value")
        XCTAssertEqual(validRefresh.value, "REFRESH+REFRESH", "refresh should have gotten the refresh value")
    }

    func testRefreshSuccessfulNilRefresh() {
        let wait100MS = XCTestExpectation(description: "Wait 100 ms finished")

        let auth = Auth(
            doGetTokens: getTokensUnused(),
            doRefreshToken: refreshTokenSuccessNilRefresh(),
            signRequest: signRequestUnused(),
            shouldDoRefreshFor: shouldDoRefreshForUnused(),
            tokenSubject: validToken,
            refreshSubject: validRefresh,
            logger: logger
        )
        
        XCTAssertEqual(validRefresh.value, "REFRESH", "the original refresh value")

        var statuses = [Auth.Status]()
        statusCancellable = auth.status
            .sink { status in
                statuses.append(status)
            }
        
        auth.forceTokenRefresh()
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            wait100MS.fulfill()
        }
        wait(for: [wait100MS], timeout: 1)
        
        let refreshingTokenOnce = statuses.filter { $0 == .refreshingToken }.count
        XCTAssertEqual(refreshingTokenOnce, 1, "should have refreshed token exactly once")
        XCTAssertEqual(statuses.last, .signedIn, "should be signed in")

        XCTAssertEqual(refreshTokenSuccessNilRefresh.callCount, 1, "should have refreshed once")
        XCTAssertEqual(validToken.value, "REFRESH+TOKEN", "token should have gotten the refresh value")
        XCTAssertEqual(validRefresh.value, "REFRESH", "refresh should be the same as the original refresh value")
    }
    
    #if !canImport(ObjectiveC)
    static var allTests: [XCTestCaseEntry] = [
        ("testRefreshSuccessful", testRefreshSuccessful),
        ("testRefreshSuccessfulNilRefresh", testRefreshSuccessfulNilRefresh),
    ]
    #endif
}

//
//  DefaultImplementations.swift
//  APIAccess
//
//  Created by Andy Bezaire on 3.3.2021.
//

import Foundation

public extension Auth {
    /// Default implementation for `shouldDoRefreshFor`.
    /// - will return true if http response status code is 403
    static let isResponseCode403: (_ forResult: URLResult) -> Bool = { result in
        if let httpResponse = result.response as? HTTPURLResponse,
           httpResponse.statusCode == 403
        {
            return true
        } else {
            return false
        }
    }

    /// Default implementation for `signRequest`.
    /// - adds header `Authorization: Bearer <token>` to request
    static let signedWithBearerToken: (_ forRequest: URLRequest, _ withToken: Token) -> URLRequest = { request, token in
        var signedRequest = request
        signedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return signedRequest
    }
}

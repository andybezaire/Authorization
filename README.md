
# Authorization
<p>
  <img src="https://img.shields.io/badge/iOS-14-orange" />
  <img src="https://img.shields.io/badge/MacOS-11-brightgreen" />
  <img src="https://img.shields.io/badge/Swift-5.3-brightgreen.svg" />
  <img src="https://img.shields.io/github/license/andybezaire/Authorization" />
  <a href="https://twitter.com/andy_bezaire">
    <img src="https://img.shields.io/twitter/url?url=http%3A%2F%2Fgithub.com%2Fandybezaire%2FAuthorization=" alt="Twitter: @andy_bezaire" />
  </a>
</p>

A small module backed by Combine. Used for authorization suitable for oauth 3 legged authorization.

## Usage

Create an authorization object:

```swift
let auth = Auth(
    doGetTokens: { /* your implementation here */ },
    doRefreshToken: { refresh in /* your implementation here */ }
)
```

Sign in:

```swift
let signingIn = auth.signIn()
    .sink(receiveCompletion: { completion in
        switch completion {
        case .failure(let error):
            print("\(error.localizedDescription)")
        case .finished:
            print("Signed in.")
        } 
    })
```

Do a fetch and Authorization will sign your URLRequest:

```swift
let request = URLRequest(url: URL(string: "example.com")!) // provide some URLRequest
let fetching = auth.fetch(request)
    .sink(receiveCompletion: { completion in
        switch completion {
        case .failure(let error):
            print("\(error.localizedDescription)")
        case .finished:
            print("Request finished.")
        }
    }, receiveValue: { data, response in
        print("Data: \(data), Response: \(response)")
    })
```

Provide a custom method to sign the request. The default is to use bearer header:

```swift
let signRequest: (_ forRequest: URLRequest, _ withToken: Auth.Token) -> URLRequest = { request, token in
    var signedRequest = request
    signedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    return signedRequest
}
```

Provide a custom method to determine when a refresh is needed. The default is to refresh when response status code is 403:

```swift
let shouldDoRefreshFor: (_ forResult: Auth.URLResult) -> Bool = { result in
    if let httpResponse = result.response as? HTTPURLResponse,
       httpResponse.statusCode == 403
    {
        return true
    } else {
        return false
    }
}
```

Provide a Logger to log to:
```swift
import os.log

let logger = Logger(subsystem: "com.example.name", category: "auth")
```

Create a customized authorization object:

```swift
let auth = Auth(
    doGetTokens: { /* your implementation here */ },
    doRefreshToken: { refresh in /* your implementation here */ },
    signRequest: signRequest,
    shouldDoRefreshFor: shouldDoRefreshFor,
    logger: logger
)
```

## Example Code

Here is an example of using Authorization to fetch from "www.example.com/name". This is a non-working example. 
Replace the `Just` publishers with  the appropriate functions to fetch your tokens and handle a refresh.

```swift
import Authorization
import Combine
import Foundation

extension ContentView {
    class Model: ObservableObject {
        lazy var auth: Auth = .init(doGetTokens: doGetTokens, doRefreshToken: doRefreshToken)
        
        func doGetTokens() -> AnyPublisher<Auth.Tokens, Error> {
            return Just(Auth.Tokens(token: "TOKEN", refresh: "REFRESH"))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        func doRefreshToken(refresh: Auth.Refresh) -> AnyPublisher<Auth.Tokens, Error> {
            return Just(Auth.Tokens(token: "TOKEN", refresh: "REFRESH"))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        var signingInOrOut: AnyCancellable?
        func signIn() {
            signingInOrOut = auth.signIn()
                .sink(receiveCompletion: { [unowned self] completion in
                    switch completion {
                    case .failure(let error):
                        print("\(error.localizedDescription)")
                    case .finished:
                        refreshName()
                    }
                })
        }
        
        func signOut() {
            signingInOrOut = auth.signOut()
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { [unowned self] completion in
                    switch completion {
                    case .failure(let error):
                        print("\(error.localizedDescription)")
                    case .finished:
                        name = nil
                    }
                })
        }
        
        @Published var name: String?
        
        func refreshName() {
            let nameURL = URL(string: "www.example.com/name")!
            let getName = URLRequest(url: nameURL)
            auth.fetch(getName)
                .map(\.data)
                .decode(type: String.self, decoder: JSONDecoder())
                .map { $0 as String? }
                .replaceError(with: nil)
                .receive(on: RunLoop.main)
                .assign(to: &$name)
        }
    }
}
```

## Installation

### Swift Package Manager

Add the following dependency to your **Package.swift** file:

```swift
.package(name: "Authorization", url: "https://github.com/andybezaire/Authorization.git", from: "1.0.0")
```
## License

"Authorization" is available under the MIT license. See the LICENSE file for more info.


## Credit

Copyright (c) 2021 andybezaire

Created by: Andy Bezaire

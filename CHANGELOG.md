# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security

## [1.4.0] - 2021-04-05
### Added
- added force token refresh intended for debug use
- added token refresh on 401 response
### Changed
- on token refresh, if the new refresh is nil, then keep the old refresh
- using refresh on 401 as default
- cleaned up logging

## [1.3.0] - 2021-04-03
### Added
- tokens now print nicely
### Changed
- cleaned up package file and added local moker fork instead of wetransfer
### Fixed
- sample app shows statuses correctly

## [1.2.1] - 2021-04-02
### Added
- new status of token expired when refresh fails

## [1.2.0] - 2021-04-02
### Added
- Publishers with Output == Never now get a sink with only receiveCompletion
### Changed
- sign in and sign out now use Never for the Output (instead of Void)
- changed the error type to Swift.Error no longer wrapping the errors in an auth error
- updated the example app to use the new api
### Removed
- removed unused auth errors

## [1.1.0] - 2021-03-29
### Changed
- renamed the repo to Authorization

## [1.0.2] - 2021-03-22

## [1.0.1] - 2021-03-22

## [1.0.0] - 2021-03-22

## [0.8.1] - 2021-03-21

## [0.8.0] - 2021-03-21

## [0.7.0] - 2021-03-20

## [0.6.0] - 2021-03-14


[Unreleased]: https://github.com/andybezaire/Authorization/compare/1.4.0...HEAD
[1.3.0]: https://github.com/andybezaire/Authorization/compare/1.3.0...1.4.0
[1.3.0]: https://github.com/andybezaire/Authorization/compare/1.2.1...1.3.0
[1.2.1]: https://github.com/andybezaire/Authorization/compare/1.2.0...1.2.1
[1.2.0]: https://github.com/andybezaire/Authorization/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/andybezaire/Authorization/compare/1.0.2...1.1.0
[1.0.2]: https://github.com/andybezaire/Authorization/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/andybezaire/Authorization/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/andybezaire/Authorization/compare/0.8.1...1.0.0
[0.8.1]: https://github.com/andybezaire/Authorization/compare/0.8.0...0.8.1
[0.8.0]: https://github.com/andybezaire/Authorization/compare/0.7.0...0.8.0
[0.7.0]: https://github.com/andybezaire/Authorization/compare/0.6.0...0.7.0
[0.6.0]: https://github.com/andybezaire/Authorization/releases/tag/0.6.0

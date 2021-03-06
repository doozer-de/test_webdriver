## 0.0.6

* Add `suiteSetUp` for initiators within the parent `suite`
* Add `suiteTearDown` for tear down callbacks within the parent `suite`
* Add `Suite.storage` to provide a key-value-storage within a `suite` shared across parent, child suites

## 0.0.5

* Print PageObject name within exception if `PageLoaderException` occurs

## 0.0.4+1

* Fix population of `PageLoaderException`
* Ignore `SocketException` when `Suite` executes `tearDownAll` (appears when the driver is no longer reachable)

## 0.0.4

* Only catch `StateError` in `withPO` (populate invalid PageObject exceptions `PageLoaderException` correctly)
* Support multiple PageObjects arguments in `withPO`
* Add `forceSuite` parameter to `withPO` to `

## 0.0.3

* Support nested suites calls to share only one suite

## 0.0.2

* Support waitFor functionality within `withPO` 
* Support capabilities configuration within configuration. Includes optional configuration of headless mode instead of explicit set (see README.md)
* Provide timeout settings

## 0.0.1

* Initial release
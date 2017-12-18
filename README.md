[![Pub](https://img.shields.io/pub/v/test_webdriver.svg)]()
[![Build Status](https://travis-ci.org/doozer-de/test_webdriver.svg?branch=master)](https://travis-ci.org/doozer-de/test_webdriver)

`test_webdriver` provides simple utility functions to setup a test environment
with a webdriver and pageloader. It makes it easier to receive pageobjects within
the testcases.

# Writing Tests

Tests which require pageobjects and a running webdriver should be within a suite block. 

```dart
import 'package:test_webdriver/test_webdriver.dart';

void main() {
  group('My Test-Suite', suite(() {
    
    test('handle login', withPO((LoginPO po) async {
      expect(await po.handleLogin('test', 'test'), isTrue);
      expect(await driver.title, contains('Dashboard of'));
    }));
  }));
}
```

There are wrapper functions which inject objects into their body function using the current `suite`:

- `withPO` injects a pageobject into the body.
- `withDriver` injects the WebDriver into the body.

These helpers are available within the body function of the previous named wrappers:

- `driver` returns the WebDriver
- `object` looks up a PageObject 

### Timeouts

Timeouts are provided by the default `timeout` settings within the `test` package. For further
details see [test README.md](https://github.com/dart-lang/test#timeouts)

```dart
test('should wait until object is available', withPO((DelayedPO po) async {
  expect(await po.element.innerText, 'test');
}), timeout: new Timeout(const Duration(seconds: 6)));
```

In order for this to work, the `test_webdriver` waits for pageobject by default. To prevent this
waiting mechanism and force an instant check use `useWaitFor: false` within `withPO`.

```dart
test('should wait until object is available', withPO((DelayedPO po) async {
  expect(await po.element.innerText, 'test');
}, useWaitFor: false));
```

In case the timeout of fetching the pageobject should differ to the timeout of the test case, use 
the specific `timeout` settings provided by `withPO`.

```dart
test('should wait until object is available', withPO((DelayedPO po) async {
  expect(await po.element.innerText, 'test');
}, timeout: const Duration(seconds: 2)), timeout: new Timeout.factor(2));
```

# Running Tests

The package doesn't ship with a selenium server, therefore the actual selenium server
(ex. chromedriver) needs to be started before running the tests. In order to run the
suite pass the environment variable `DRIVER_URI` to the test process.

```
DRIVER_URI=http://localhost:9515/ pub run test
```

## Setting up chrome headless

To run chrome in headless mode setup the proper configuration in `dart_webdriver.yaml`:

```yaml
capabilities:
  chromeOptions:
    args: ['--headless']
```
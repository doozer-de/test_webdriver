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
    }));
  }));
}
```

# Running Tests

The package doesn't ship with a selenium server, therefore the actual selenium server
(ex. chromedriver) needs to be started before running the tests. In order to run the
suite pass the environment variable `DRIVER_URI` to the test process.

```
DRIVER_URI=http://localhost:9515/ pub run test
```
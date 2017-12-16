import 'dart:async';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:webdriver/io.dart';
import 'package:test_webdriver/src/backend/suite.dart';

class MockWebDriver extends Mock implements WebDriver {}

void main() {
  group('Suite', () {
    test('should initiate a new suite if not exists', () {
      var suite = Suite.current;

      suite.run(() {
        expect(suite, equals(Suite.current));
      });

      expect(suite, isNot(equals(Suite.current)));
    });

    test('should setUp the webdriver', () {
      var suite = new Suite();

      suite.environment = {'DRIVER_URI': 'http://localhost:9090/'};

      suite.driverFactory = expectAsync2((Uri uri, Map<String, String> capabilities) {
        expect(uri.host, 'localhost');
        expect(uri.port, 9090);
        return new Future.value(new MockWebDriver());
      });

      suite.setUp();
    });
  });
}
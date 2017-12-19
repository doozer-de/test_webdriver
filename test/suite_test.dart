import 'dart:async';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:webdriver/io.dart';
import 'package:test_webdriver/src/backend/suite.dart';
import 'package:test_webdriver/src/backend/configuration.dart';

class MockWebDriver extends Mock implements WebDriver {}

void main() {
  group('Suite', () {
    test('should initiate a new suite if not exists', () {
      var suite = Suite.current;

      suite.run(() {
        expect(suite, same(Suite.current));
      });

      expect(suite, isNot(same(Suite.current)));
    });

    test('should setUp the webdriver', () {
      var suite = new Suite(
          env: {'DRIVER_URI': 'http://localhost:9090/'},
          driverFactory:
              expectAsync2((Uri uri, Map<String, String> capabilities) {
            expect(uri.host, 'localhost');
            expect(uri.port, 9090);
            return new Future.value(new MockWebDriver());
          }),
          configurationLoader: () =>
              new Future.value(new Configuration.fromMap({})));

      suite.setUp();
    });

    test('should pass capabilities to webdriver', () {
      var suite = new Suite(
          env: {
            'DRIVER_URI': 'http://localhost:9090/',
            'DRIVER_PLATFORM': 'testplatform',
          },
          driverFactory:
              expectAsync2((Uri uri, Map<String, String> capabilities) {
            expect(capabilities,
                equals({'test': true, 'platform': 'testplatform'}));
            return new Future.value(new MockWebDriver());
          }),
          configurationLoader: () =>
              new Future.value(new Configuration.fromMap({
                'capabilities': {'test': true},
              })));

      suite.setUp();
    });
  });
}

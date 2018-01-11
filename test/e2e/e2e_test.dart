import 'dart:async';
import 'dart:io';

import 'package:pageloader/webdriver.dart';
import 'package:metatest/metatest.dart';
import 'package:test/test.dart';
import 'package:test_webdriver/src/backend/configuration.dart';
import 'package:test_webdriver/src/backend/suite.dart';
import 'package:test_webdriver/test_webdriver.dart';
import 'testcase/case_setup.dart';
import 'testcase/hello_po.dart';

Future main() async {
  HttpServer server = await setupServer();
  Suite testSuite = new Suite(
      env: {
        'DRIVER_URI': 'http://localhost:9515',
      },
      configurationLoader: () => new Future.value(new Configuration.fromMap({
            'capabilities': {
              'chromeOptions': {
                'args': ['--headless']
              }
            }
          })));
  Process chromeDriver = await setupChromeDriver();

  testSuite.run(() {
    group('e2e testcase', suite(() {
      tearDownAll(() async {
        await server.close();
        await chromeDriver.kill();
      });

      group('run the suite', () {
        test('should open the page', withDriver((WebDriver driver) async {
          var addr = 'http://${server.address.host}:${server.port}/';
          await driver.get(addr);
          expect(await driver.currentUrl, contains(addr));
        }));

        test('should contain the hello PO', withPO((HelloPO po) async {
          expect(await po.content, equals('Hello'));
        }));

        test('should contain the HelloPO and SecondPO',
            withPO((HelloPO po, SecondPO po2) async {
          expect(await po.content, equals('Hello'));
          expect(await po2.content, equals('Test 2'));
        }));

        expectTestsFail('should fail because PO errors', () {
          // force suite is necessary because of the different zones within
          // expectTestsFail
          test(
              'trying to fetch not existing PO',
              withPO((NotExistingPO po) {
                expect(true, isTrue);
              }, forceSuite: testSuite, useWaitFor: false));

          test(
              'trying to fetch invalid PO',
              withPO((InvalidExistingPO po) {
                expect(true, isTrue);
              }, forceSuite: testSuite, useWaitFor: false));
        });

        group('sanity test PO exceptions', () {
          test('should throw not existing PO object', withDriver((_) async {
            expect(
                object(NotExistingPO), throwsA(new isInstanceOf<StateError>()));
          }));

          test('should throw invalid PO object', withDriver((_) async {
            expect(object(InvalidExistingPO),
                throwsA(new isInstanceOf<PageLoaderException>()));
            expect(object(InvalidExistingPO),
                throwsA(isNot(new isInstanceOf<StateError>())));
          }));
        });
      });
    }));
  });
}

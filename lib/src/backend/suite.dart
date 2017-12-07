import 'dart:async';
import 'dart:io' show File, Platform;

import 'package:pageloader/webdriver.dart';
import 'package:webdriver/io.dart';

import 'configuration.dart';

/// Provides the setup and teardown of a suite which initiates a webdriver by
/// the provided environment variables.
class Suite {
  static Suite get current {
    if (Zone.current[#test_webdriver.suite] == null) {
      return new Suite();
    }

    return Zone.current[#test_webdriver.suite];
  }

  Configuration configuration;
  String driverUri;
  WebDriver driver;
  PageLoader loader;

  Map<String, String> capabilities = {};

  Future handle(String testCase, [dynamic err]) async {
    if (configuration == null) {
      configuration = await loadConfig();
    }

    if (configuration.captureScreenshotOnSuccess && err == null) {
      await captureScreenshot(testCase, false);
    } else if (configuration.captureScreenshotOnError && err != null) {
      await captureScreenshot(testCase, true);
    }
  }

  Future captureScreenshot(String t, bool err) async {
    var file = new File(
        '${configuration.screenshotPath}/${t}_${err ? 'error' : 'success'}.png');
    return file.writeAsBytes(await driver.captureScreenshotAsList());
  }

  R run<R>(R body()) {
    return runZoned(body, zoneValues: {
      #test_webdriver.suite: this,
    });
  }

  Future setUp() async {
    driverUri = Platform.environment['DRIVER_URI'];

    if (Platform.environment.containsKey('DRIVER_BROWSER')) {
      capabilities['browser'] = Platform.environment['DRIVER_BROWSER'];
    }

    if (Platform.environment.containsKey('DRIVER_PLATFORM')) {
      capabilities['platform'] = Platform.environment['DRIVER_PLATFORM'];
    }

    if (Platform.environment.containsKey('DRIVER_VERSION')) {
      capabilities['version'] = Platform.environment['DRIVER_VERSION'];
    }

    driver = await createDriver(
        uri: Uri.parse(driverUri),
        desired: {}
          ..addAll(Capabilities.chrome)
          ..addAll(capabilities)
          ..addAll({
            'chromeOptions': {
              'args': ['--headless']
            }
          }));
    loader = new WebDriverPageLoader(driver);
  }

  Future tearDown() {
    return driver.quit();
  }
}

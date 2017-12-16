import 'dart:async';
import 'dart:io' show File, Platform;

import 'package:pageloader/webdriver.dart';
import 'package:webdriver/io.dart';

import 'configuration.dart';

typedef Future<Configuration> _SuiteConfigurationLoader();
typedef Future<WebDriver> _DriverFactory(
    Uri driverUri, Map<String, String> capabilities);

/// Provides the setup and teardown of a suite which initiates a webdriver by
/// the provided environment variables.
class Suite {
  static Suite get current {
    if (Zone.current[#test_webdriver.suite] == null) {
      return new Suite();
    }

    return Zone.current[#test_webdriver.suite];
  }

  /// Function used to load the configuration.
  _SuiteConfigurationLoader configurationLoader = loadConfig;

  /// Function used to initiate the [WebDriver].
  _DriverFactory driverFactory = _defaultWebDriverFactory;

  Map<String, String> environment = Platform.environment;

  Configuration configuration;
  String driverUri;
  WebDriver driver;
  PageLoader loader;

  Map<String, String> capabilities = {};

  Future handle(String testCase, [dynamic err]) async {
    if (configuration == null) {
      configuration = await configurationLoader();
    }

    if (configuration.captureScreenshotOnSuccess && err == null) {
      await captureScreenshot(testCase, false);
    } else if (configuration.captureScreenshotOnError && err != null) {
      await captureScreenshot(testCase, true);
    }
  }

  Future captureScreenshot(String t, bool err) async {
    var file = new File('${configuration.screenshotPath}/${t}_${err
        ? 'error'
        : 'success'}.png');
    return file.writeAsBytes(await driver.captureScreenshotAsList());
  }

  R run<R>(R body()) {
    return runZoned(body, zoneValues: {
      #test_webdriver.suite: this,
    });
  }

  Future setUp() async {
    driverUri = environment['DRIVER_URI'];

    if (environment.containsKey('DRIVER_BROWSER')) {
      capabilities['browser'] = environment['DRIVER_BROWSER'];
    }

    if (environment.containsKey('DRIVER_PLATFORM')) {
      capabilities['platform'] = environment['DRIVER_PLATFORM'];
    }

    if (environment.containsKey('DRIVER_VERSION')) {
      capabilities['version'] = environment['DRIVER_VERSION'];
    }

    driver = await driverFactory(Uri.parse(driverUri), capabilities);
    loader = new WebDriverPageLoader(driver);
  }

  Future tearDown() {
    return driver.quit();
  }
}

Future<WebDriver> _defaultWebDriverFactory(
        Uri driverUri, Map<String, String> capabilities) =>
    createDriver(
        uri: driverUri,
        desired: {}
          ..addAll(Capabilities.chrome)
          ..addAll(capabilities)
          ..addAll({
            'chromeOptions': {
              'args': ['--headless']
            }
          }));

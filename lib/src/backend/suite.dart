import 'dart:async';
import 'dart:io' show File, Platform, SocketException;

import 'package:meta/meta.dart';
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

    Suite suite = Zone.current[#test_webdriver.suite];
    suite._nested = (Zone.current[#test_webdriver.level] ?? 0) > 1;

    return suite;
  }

  /// Storage can be used to share data across suites.
  static Map<String, dynamic> get storage {
    var suite = current;
    return suite._storage;
  }

  /// Factory function to load the [Configuration], by default this will use the
  /// [loadConfig] function to load the "dart_webdriver.yaml" in the project
  /// root.
  final _SuiteConfigurationLoader configurationLoader;

  /// Factory used by [setUp] to initiate the [WebDriver]. This can be overridden
  /// for test purpose.
  final _DriverFactory driverFactory;

  /// Contains configuration variables which are by default the environment
  /// variables.
  final Map<String, String> environment;

  /// Storage can be used to share data across suites.
  final Map<String, dynamic> _storage = {};

  @visibleForTesting
  Map<String, dynamic> get internalStorage => _storage;

  Configuration _configuration;
  bool _nested = false;

  /// Uri of the selenium server. This is passed using the environment variable
  /// "DRIVER_URI".
  String _driverUri;
  WebDriver _driver;
  bool _driverQuitted = false;

  /// The active [WebDriver] for this suite. The driver is only available after
  /// [setUp] is called.
  WebDriver get driver => _driver;

  PageLoader _loader;
  bool _registered = false;

  Function _tearDownCallback;
  set tearDownCallback(callback()) {
    if (!_nested) {
      _tearDownCallback = callback;
    }
  }

  Function _setUpCallback;
  set setUpCallback(callback()) {
    if (!_nested) {
      _setUpCallback = callback;
    }
  }

  /// The [PageLoader] is only available after [setUp] is called.
  PageLoader get loader => _loader;

  Map<String, dynamic> _capabilities = {};

  Suite(
      {Map<String, dynamic> env,
      this.driverFactory: _defaultWebDriverFactory,
      this.configurationLoader: loadConfig})
      : environment = env ?? Platform.environment;

  /// Completes a testcase by checking for an [error] and capture a screenshot
  /// in case the configuration is set up properly.
  Future handle(String testCase, [dynamic error]) async {
    if (_configuration == null) {
      _configuration = await configurationLoader();
    }

    if (_configuration.captureScreenshotOnSuccess && error == null) {
      await captureScreenshot(testCase, false);
    } else if (_configuration.captureScreenshotOnError && error != null) {
      await captureScreenshot(testCase, true);
    }
  }

  /// Creates a screenshot with the a suffix "error" if [err] is set to true or
  /// "success" in the [Configuration.screenshotPath] within the project root
  /// directory.
  Future captureScreenshot(String t, bool err) async {
    var file = new File('${_configuration.screenshotPath}/${t}_${err
        ? 'error'
        : 'success'}.png');
    return file.writeAsBytes(await driver.captureScreenshotAsList());
  }

  /// Runs [body] within a new zone which has the [Suite] saved as a zone
  /// variable. [Suite.current] than returns this instance instead of a new one.
  R run<R>(R body()) {
    return runZoned(body, zoneValues: {
      #test_webdriver.suite: this,
      #test_webdriver.level: (Zone.current[#test_webdriver.level] ?? 0) + 1,
    });
  }

  /// Registers the suite in a test group in case it's not already registered.
  void register(Function setUpAll, Function tearDownAll) {
    if (_registered) {
      return;
    }

    _registered = true;
    setUpAll(setUp);
    tearDownAll(tearDown);
  }

  /// This method is registered to the setUpAll test method when using suite.
  /// It initiates the [WebDriver] using the [driverFactory].
  Future setUp() async {
    if (_configuration == null) {
      _configuration = await configurationLoader();
    }

    _driverUri = environment['DRIVER_URI'];

    if (environment.containsKey('DRIVER_BROWSER')) {
      _capabilities['browser'] = environment['DRIVER_BROWSER'];
    }

    if (environment.containsKey('DRIVER_PLATFORM')) {
      _capabilities['platform'] = environment['DRIVER_PLATFORM'];
    }

    if (environment.containsKey('DRIVER_VERSION')) {
      _capabilities['version'] = environment['DRIVER_VERSION'];
    }

    _capabilities.addAll(_configuration.capabilities);

    _driver = await driverFactory(Uri.parse(_driverUri), _capabilities);
    _loader = new WebDriverPageLoader(_driver);

    if (_setUpCallback != null) {
      await run(_setUpCallback);
    }
  }

  /// This method is registered to the tearDownAll test method to shut down the
  /// [WebDriver].
  Future<dynamic> tearDown() async {
    if (_tearDownCallback != null) {
      await run(_tearDownCallback);
    }

    if (_driverQuitted) {
      return true;
    }
    _driverQuitted = true;
    return _driver.quit().catchError((_) {
      /* ignore if socket is already closed */
    }, test: (e) => e is SocketException);
  }
}

Future<WebDriver> _defaultWebDriverFactory(
        Uri driverUri, Map<String, dynamic> capabilities) =>
    createDriver(uri: driverUri, desired: capabilities);

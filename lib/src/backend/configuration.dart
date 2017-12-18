import 'dart:async';
import 'dart:io';

import 'package:yaml/yaml.dart';

/// Provides a basic configuration for the test suits.
class Configuration {
  bool captureScreenshotOnError = false;
  bool captureScreenshotOnSuccess = false;
  Map<String, dynamic> capabilities = {};

  /// Relative path to the working directory in which the tests are executed.
  String screenshotPath = 'test_screenshots';

  Configuration.fromMap(Map<String, dynamic> v) {
    var screen = v['screenshot'] ?? {};
    captureScreenshotOnError = screen['onError'] ?? false;
    captureScreenshotOnSuccess = screen['onSuccess'] ?? false;
    screenshotPath = screen['output'] ?? 'test_screenshots';
    capabilities = v['capabilities'] ?? {};
  }
}

/// Loads the configuration from the working directory.
Future<Configuration> loadConfig() async {
  var file = new File('dart_webdriver.yaml');
  if (!await file.exists()) return new Configuration.fromMap({});

  var yaml = loadYaml(await file.readAsString());
  return new Configuration.fromMap(yaml);
}

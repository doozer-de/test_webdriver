import 'dart:async';
import 'dart:io';

import 'package:yaml/yaml.dart';

/// Provides a basic configuration for the test suits.
class Configuration {
  bool captureScreenshotOnError = false;
  bool captureScreenshotOnSuccess = false;

  /// Relative path to the working directory in which the tests are executed.
  String screenshotPath = 'test_screenshots';

  Configuration._(Map<String, dynamic> v) {
    var screen = v['screenshot'] ?? {};
    captureScreenshotOnError = screen['onError'] ?? false;
    captureScreenshotOnSuccess = screen['onSuccess'] ?? false;
    screenshotPath = screen['output'] ?? 'test_screenshots';
  }
}

/// Loads the configuration from the working directory.
Future<Configuration> loadConfig() async {
  var file = new File('dart_webdriver.yaml');
  if (!await file.exists()) return new Configuration._({});

  var yaml = loadYaml(await file.readAsString());
  return new Configuration._(yaml);
}

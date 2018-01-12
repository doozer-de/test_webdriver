import 'dart:io';

import 'dart:mirrors';
import 'package:yaml/yaml.dart';

/// Provides a basic configuration for the test suits.
class Configuration {
  bool captureScreenshotOnError = false;
  bool captureScreenshotOnSuccess = false;
  Map<String, dynamic> capabilities = {};

  /// Contains configuration for the testcases available within the suite runner.
  Map<String, dynamic> configuration = {};

  /// Relative path to the working directory in which the tests are executed.
  String screenshotPath = 'test_screenshots';

  Configuration.fromMap(Map<String, dynamic> v) {
    var screen = v['screenshot'] ?? {};
    captureScreenshotOnError = screen['onError'] ?? false;
    captureScreenshotOnSuccess = screen['onSuccess'] ?? false;
    screenshotPath = screen['output'] ?? 'test_screenshots';
    capabilities = v['capabilities'] ?? {};
    configuration = v['configuration'] ?? {};
  }

  void apply(Function body, [String configName]) {
    var bodyMirror = reflect(body) as ClosureMirror;

    // no configuration required
    if (bodyMirror.function.parameters.isEmpty) {
      body();
      return;
    }

    assert(bodyMirror.function.parameters.length == 1,
        'only one configuration parameter is supported in suite runner');

    var configurationType = bodyMirror.function.parameters.first.type;
    assert(configurationType is ClassMirror,
        'only classes are supported as configuration paramter');

    var config = configName != null ? configuration[configName] : configuration;

    var configurationInstance =
        (configurationType as ClassMirror).newInstance(#fromMap, [config]);
    body(configurationInstance.reflectee);
  }
}

/// Loads the configuration from the working directory.
Configuration loadConfig() {
  var file = new File('dart_webdriver.yaml');
  if (!file.existsSync()) return new Configuration.fromMap({});

  var yaml = loadYaml(file.readAsStringSync());
  return new Configuration.fromMap(yaml);
}

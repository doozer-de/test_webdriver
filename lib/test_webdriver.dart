library test_webdriver;

import 'dart:async';
import 'dart:mirrors';

import 'package:test/test.dart' as ts;
import 'package:webdriver/io.dart';
import 'src/backend/suite.dart';

export 'package:test/test.dart';
export 'package:webdriver/io.dart' show WebDriver;

/// Creates a new test suite with a selenium context. It will register a
/// setUpAll function to initiate the webdriver and a tearDown to deregister
/// it.
ts.Func0 suite(body()) {
  var suite = Suite.current;

  return () {
    suite.run(() {
      ts.setUpAll(suite.setUp);
      ts.tearDownAll(suite.tearDown);

      body();
    });
  };
}

/// Injects the driver of the current suite into the passed function.
Function withDriver(Function fn) {
  var suite = Suite.current;

  return () async {
    return suite.run(() async {
      var driver = suite.driver;
      await fn(driver);
    });
  };
}

/// Detects the type of the first argument within the passed [fn] function,
/// tries to load it using the loader of the current suite and injects it into
/// the function. The test case performed in this function is wrapped and
/// the suite will perform followup functionality like taking screenshots.
Function withPO(Function fn, {String screenshotName}) {
  var suite = Suite.current;
  var mirr = reflect(fn) as ClosureMirror;

  return () async {
    return suite.run(() async {
      var po = await suite.loader
          .getInstance(mirr.function.parameters.first.type.reflectedType);

      var exception;
      try {
        await fn(po);
      } catch (ex) {
        exception = ex;
      } finally {
        await suite.handle(screenshotName ?? new DateTime.now().toIso8601String(), exception);
        if (exception != null) {
          throw exception;
        }
      }
    });
  };
}

/// Contains the current active web driver for this suite. This can only be
/// performed within functions that provide the suite zone environment like:
/// withPO, withDriver.
WebDriver get driver => Suite.current.driver;

/// Returns a pageobject of the current active view. This function can only be
/// called within functions that provide the suite zone environment like:
/// withPO, withDriver.
Future<T> object<T>(Type t) => Suite.current.loader.getInstance(t);

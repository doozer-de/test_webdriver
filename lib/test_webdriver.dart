library test_webdriver;

import 'dart:async';
import 'dart:mirrors';

import 'package:pageloader/webdriver.dart';
import 'package:test/test.dart' as ts;
import 'package:webdriver/io.dart';
import 'package:webdriver/support/async.dart';
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
      suite.register(ts.setUpAll, ts.tearDownAll);
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
///
/// Set [useWaitFor] to false in case the pageloader should instantly throw
/// an exception if a pageobject is not present on test execution. Otherwise the
/// pageloader will try to load the pageobject until the test times out.
///
/// Use [timeout] to define a separate timeout for the pageloader to fetch the
/// pageobject apart from the test specific timeout. For further details on the
/// default timeout, see [test] package documentation.
///
/// Use [forceSuite] if there's a separated zone layer used within your
/// testcases. This is for example the case when using [metatest] package. See
/// test/e2e/e2e_test.dart for a proper workaround.
Function withPO(Function fn,
    {String screenshotName,
    bool useWaitFor: true,
    Duration timeout: const Duration(days: 1),
    Suite forceSuite}) {
  var suite = forceSuite ?? Suite.current;
  var mirr = reflect(fn) as ClosureMirror;

  assert(mirr.function.parameters.isNotEmpty,
      'expect withPO body to have at least one argument');

  return () async {
    return suite.run(() async {
      Iterable<Future<dynamic>> waitings;

      if (useWaitFor) {
        waitings = mirr.function.parameters
            .map((param) => param.type.reflectedType)
            .map((type) => waitFor(
                () => suite.loader.getInstance(type).catchError((err) => err,
                    test: (err) => err is PageLoaderException),
                matcher:
                    ts.isNot(ts.throwsA(new ts.isInstanceOf<StateError>())),
                timeout: timeout));
      } else {
        waitings = mirr.function.parameters
            .map((param) => param.type.reflectedType)
            .map((type) => suite.loader.getInstance(type).catchError(
                (err) => err,
                test: (err) => err is PageLoaderException));
      }

      List<dynamic> pageObjects = await Future.wait(waitings);

      // throw exceptions when exists
      for (var i = 0; i < mirr.function.parameters.length; i++) {
        if (pageObjects[i] is PageLoaderException) {
          throw new TestWebDriverException(
              mirr.function.parameters[i].type.simpleName.toString(),
              pageObjects[i]);
        }
      }

      var exception;
      try {
        var result = Function.apply(fn, pageObjects);
        if (result is Future) {
          await result;
        }
      } catch (ex) {
        exception = ex;
      } finally {
        await suite.handle(
            screenshotName ?? new DateTime.now().toIso8601String(), exception);
        if (exception != null) {
          throw exception;
        }
      }
    });
  };
}

/// Registers a function to be run once before all tests and only in the main
/// suite.
/// If the suite is nested within another suite, this callback will be quietly
/// ignored. This can be useful to setup initial data used for the testcase
/// when it runs as a single test suite. When wrapped in a chain of tests, this
/// data may be provided by other tests which can run in a complete case.
void suiteSetUp(callback()) {
  Suite.current.setUpCallback = callback;
}

/// Registers a function to be run once after all tests and only in the main
/// suite.
/// If the suite is nested within another suite, this callback will be quietly
/// ignored. This can be useful to remove initial data used for the testcase
/// when it runs as a single test suite. When wrapped in a chain of tests, this
/// data may be provided by other tests which can run in a complete case.
void suiteTearDown(callback()) {
  Suite.current.tearDownCallback = callback;
}

/// Contains the current active web driver for this suite. This can only be
/// performed within functions that provide the suite zone environment like:
/// withPO, withDriver.
WebDriver get driver => Suite.current.driver;

/// Returns a pageobject of the current active view. This function can only be
/// called within functions that provide the suite zone environment like:
/// withPO, withDriver.
Future<T> object<T>(Type t) => Suite.current.loader.getInstance(t);

/// Wraps the [PageLoaderException] to properly print the affected PageObject.
class TestWebDriverException implements Exception {
  final PageLoaderException pageLoaderException;
  final String pageObjectType;

  TestWebDriverException(this.pageObjectType, this.pageLoaderException);

  @override
  String toString() =>
      '''TestWebDriverException for pageobject: ${pageObjectType}
  $pageLoaderException''';
}

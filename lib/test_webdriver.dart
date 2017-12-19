library test_webdriver;

import 'dart:async';
import 'dart:mirrors';

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
Function withPO(Function fn,
    {String screenshotName,
    bool useWaitFor: true,
    Duration timeout: const Duration(days: 1)}) {
  var suite = Suite.current;
  var mirr = reflect(fn) as ClosureMirror;

  assert(mirr.function.parameters.isNotEmpty,
      'expect withPO body to have an argument');

  var argType = mirr.function.parameters.first.type.reflectedType;

  return () async {
    return suite.run(() async {
      var po;

      if (useWaitFor) {
        po = await waitFor(() => suite.loader.getInstance(argType),
            matcher: ts.isNot(
                ts.throwsA(new ts.isInstanceOf<NoSuchElementException>())),
            timeout: timeout);
      } else {
        po = await suite.loader.getInstance(argType);
      }

      var exception;
      try {
        await fn(po);
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

/// Contains the current active web driver for this suite. This can only be
/// performed within functions that provide the suite zone environment like:
/// withPO, withDriver.
WebDriver get driver => Suite.current.driver;

/// Returns a pageobject of the current active view. This function can only be
/// called within functions that provide the suite zone environment like:
/// withPO, withDriver.
Future<T> object<T>(Type t) => Suite.current.loader.getInstance(t);

library test_webdriver;

import 'dart:async';
import 'dart:mirrors';

import 'package:test/test.dart' as ts;
import 'package:webdriver/io.dart';
import 'package:webdriver/support/async.dart';
import 'src/backend/suite.dart';

export 'package:test/test.dart';
export 'package:webdriver/io.dart' show WebDriver;

typedef FutureOr<R> _ReturnFunc<R>();

/// Creates a new test suite with a selenium context. It will register a
/// setUpAll function to initiate the webdriver and a tearDown to deregister
/// it.
Function suite(Function body) {
  var suite = Suite.current;

  return () {
    suite.run(() {
      suite.register(ts.setUpAll, ts.tearDownAll);
      suite.apply(body);
    });
  };
}

/// Injects the driver of the current suite into the passed function.
_ReturnFunc<R> withDriver<R>(R fn(WebDriver w)) {
  var suite = Suite.current;
  return () => suite.run(() => fn(suite.driver));
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
            .map((type) => waitFor(() => suite.loader.getInstance(type),
                matcher:
                    ts.isNot(ts.throwsA(new ts.isInstanceOf<StateError>())),
                timeout: timeout));
      } else {
        waitings = mirr.function.parameters
            .map((param) => param.type.reflectedType)
            .map((type) => suite.loader.getInstance(type));
      }

      List<dynamic> pageObjects = await Future.wait(waitings);

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

/// Contains the current active web driver for this suite. This can only be
/// performed within functions that provide the suite zone environment like:
/// withPO, withDriver.
WebDriver get driver => Suite.current.driver;

/// Returns a pageobject of the current active view. This function can only be
/// called within functions that provide the suite zone environment like:
/// withPO, withDriver.
Future<T> object<T>(Type t) => Suite.current.loader.getInstance(t);

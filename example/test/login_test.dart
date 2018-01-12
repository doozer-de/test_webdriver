import 'dart:async';

import 'package:test_webdriver/test_webdriver.dart';
import 'package:pageloader/objects.dart';

void main() {
  group('login', suite((LoginTestConfig config) {
    setUpAll(
        withDriver((driver) => driver.get('http://localhost:8080/index.html')));

    test('should contain the login form', withPO((LoginPO po) async {
      await po.form.login(config.username, config.password);
      var uri = Uri.parse(await driver.currentUrl);

      expect(uri.queryParameters['username'], config.username);
      expect(uri.queryParameters['password'], config.password);
    }));

    test('should navigate to another page', withPO((LoginPO po) async {
      await po.navigate();
      expect(await driver.currentUrl, contains('another.html'));
    }));

    test(
        'should fail',
        withPO((AnotherPO po) async {
          await po.notExists.call();
        }, screenshotName: 'not_exists'));

    test('should wait until object is available', withPO((DelayedPO po) async {
      expect(await po.element.innerText, 'test');
    }), timeout: new Timeout(const Duration(seconds: 6)));
  }));
}

@ByClass('login-page')
class LoginPO {
  @ByTagName('form')
  LoginFormPO form;

  @ById('alink')
  PageLoaderElement _link;

  Future navigate() => _link.click();
}

class LoginFormPO {
  @ById('username')
  PageLoaderElement _username;

  @ById('password')
  PageLoaderElement _password;

  @FirstByCss('input[type="submit"]')
  PageLoaderElement _submit;

  Future<Null> login(String username, String password) async {
    await _username.type(username);
    await _password.type(password);
    await _submit.click();
  }
}

class LoginTestConfig {
  String username;
  String password;

  LoginTestConfig.fromMap(Map<String, dynamic> config)
      : username = config['username'] as String,
        password = config['password'] as String;
}

@ById('another')
class AnotherPO {
  @ByTagName('p')
  PageLoaderElement _content;

  @ById('notExists')
  Lazy<PageLoaderElement> notExists;

  Future<String> get content => _content.innerText;
}

@ById('delayed')
class DelayedPO {
  @root
  PageLoaderElement element;
}

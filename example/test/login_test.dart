import 'package:test_webdriver/test_webdriver.dart';
import 'package:example/login_po.dart';

void main() {
  group('login', suite(() {
    setUpAll(withDriver(
        (WebDriver driver) => driver.get('http://localhost:8080/index.html')));

    test('should contain the login form', withPO((LoginPO po) async {
      await po.form.login('test', 'test');
      var uri = Uri.parse(await driver.currentUrl);

      expect(uri.queryParameters['username'], 'test');
      expect(uri.queryParameters['password'], 'test');
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
  }));
}

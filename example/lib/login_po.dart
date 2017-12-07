import 'dart:async';

import 'package:pageloader/objects.dart';

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

@ById('another')
class AnotherPO {
  @ByTagName('p')
  PageLoaderElement _content;

  @ById('notExists')
  Lazy<PageLoaderElement> notExists;

  Future<String> get content => _content.innerText;
}

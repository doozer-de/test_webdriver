import 'dart:async';

import 'package:pageloader/src/annotations.dart';
import 'package:pageloader/webdriver.dart';

@ByCss('.hello')
class HelloPO {
  @root
  PageLoaderElement _element;

  Future<String> get content => _element.innerText;
}

@ByCss('.not-existing')
class NotExistingPO {}

@ByCss('.invalid-po')
class InvalidExistingPO {
  @ByCss('.not-exists')
  PageLoaderElement _notExisting;

  @ByCss('.exists')
  PageLoaderElement _child;
}

@ByCss('.test2')
class SecondPO extends HelloPO {}
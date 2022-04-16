import 'dart:io';

import 'package:args/args.dart';
import 'package:tekartik_build_menu_flutter/app_build_menu.dart';

Future<void> main(List<String> arguments) async {
  await fbm(arguments);
}

Future<void> fbm(List<String> arguments) async {
  var parser = ArgParser();
  var result = parser.parse(arguments);
  var appPath = result.rest;

  if (appPath.isEmpty) {
    appPath = [Directory.current.path];
  }
  mainMenu(appPath.sublist(1), () {
    menuAppContent(path: appPath.first);
  });
}

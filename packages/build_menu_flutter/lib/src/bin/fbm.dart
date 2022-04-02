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
    stderr.writeln('Missing path');
    exit(1);
  }
  mainMenu(arguments, () {
    menuAppContent(path: appPath.first);
  });
}

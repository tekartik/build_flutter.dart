import 'dart:io';

import 'package:tekartik_app_args/arg_parser.dart';
import 'package:tekartik_build_menu_flutter/app_build_menu.dart';

Future<void> main(List<String> arguments) async {
  fbm(arguments);
}

void fbm(List<String> arguments) {
  var flagHelp = Flag.arg('help', abbr: 'h', help: 'Display help');
  var optionFlavors = MultiOption.arg('flavors', help: 'Flavors');
  var parser = ArgumentParser()..addArguments([flagHelp, optionFlavors]);
  var result = parser.parse(arguments);
  if (flagHelp.on) {
    print('fbm [options] [path]');
    print(parser.raw.usage);
    exit(0);
  }
  var appPath = result.raw.rest;

  if (appPath.isEmpty) {
    appPath = [Directory.current.path];
  }
  mainMenu(appPath.sublist(1), () {
    menuAppContent(path: appPath.first, flavors: optionFlavors.list);
  });
}

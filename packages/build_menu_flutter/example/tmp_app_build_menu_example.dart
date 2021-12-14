import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_build_menu_flutter/app_build_menu.dart';

Future main(List<String> arguments) async {
  var appPath = join('.dart_tool', 'tekartik_build_menu_flutter',
      'example_flutter', 'app_build_menu_example');
  try {
    await Directory(appPath).delete(recursive: true);
  } catch (_) {}
  mainMenu(arguments, () {
    menuAppContent(path: appPath);
  });
}

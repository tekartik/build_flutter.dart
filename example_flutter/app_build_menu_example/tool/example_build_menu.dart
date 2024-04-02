import 'dart:io';

import 'package:tekartik_build_menu_flutter/app_build_menu.dart';

Future main(List<String> arguments) async {
  var appPath = '.';
  mainMenuConsole(arguments, () {
    if (Platform.isWindows || Platform.isLinux) {
      item('build and run marker', () async {
        await createProject('.');
        await buildProject('.', target: 'lib/create_file_and_exit_main.dart');
        await runBuiltProject('.');
      });
      item('build and run example', () async {
        await createProject('.');
        await buildProject('.');
        await runBuiltProject('.');
      });
    }
    menuAppContent(path: appPath);
  });
}

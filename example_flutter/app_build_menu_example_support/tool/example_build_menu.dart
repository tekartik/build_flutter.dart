import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_build_menu_flutter/app_build_menu.dart';

/// Added here to test on an exter
Future main(List<String> arguments) async {
  var appPath = join('..', 'app_build_menu_example');
  mainMenuConsole(arguments, () {
    if (Platform.isWindows || Platform.isLinux) {
      item('build and run marker', () async {
        await createProject(appPath);
        await buildProject(appPath,
            target: 'lib/create_file_and_exit_main.dart');
        await runBuiltProject(appPath);
      });
      item('build and run example', () async {
        await createProject(appPath);
        await buildProject(appPath);
        await runBuiltProject(appPath);
      });
    }
    menuAppContent(path: appPath);
  });
}

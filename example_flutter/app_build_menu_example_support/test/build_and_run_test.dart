import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_build_menu_flutter/app_build_menu.dart';
import 'package:test/test.dart';

void main() {
  test('create_and_build_app', () async {
    var appPath = join('..', 'app_build_menu_example');
    await createProject(appPath);
    await buildProject(appPath, target: 'lib/create_file_and_exit_main.dart');
  },
      skip: !(Platform.isLinux || Platform.isWindows || Platform.isMacOS),
      timeout: const Timeout(Duration(minutes: 10)));
}

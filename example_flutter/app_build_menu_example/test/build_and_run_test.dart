import 'dart:io';

import 'package:app_build_menu_example/create_file_and_exit_main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:tekartik_build_menu_flutter/app_build_menu.dart';

void main() {
  test('build_and_run', () async {
    await Shell().run('flutter doctor -v');
    await createProject('.');
    await buildProject('.', target: 'lib/create_file_and_exit_main.dart');
    var markerPath = join(platformExeDir, markerFile);
    await deleteFile(markerPath);
    expect(File(markerPath).existsSync(), isFalse);
    await Shell(workingDirectory: platformExeDir)
        .run(join('.', 'app_build_menu_example'));
    expect(File(markerPath).existsSync(), isTrue);
  });
}

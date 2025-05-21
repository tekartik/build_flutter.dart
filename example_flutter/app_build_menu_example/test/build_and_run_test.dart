import 'dart:io';

import 'package:app_build_menu_example/create_file_and_exit_main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:tekartik_build_menu_flutter/app_build_menu.dart';

var runningOnGithubAction = Platform.environment['GITHUB_ACTION'] != null;

void main() {
  test(
    'build_and_run',
    () async {
      if (true) {
        await Shell().run('flutter doctor -v');
        await createProject('.');
        await buildProject('.', target: 'lib/create_file_and_exit_main.dart');
      }
      var appName = await getBuildProjectAppFilename('.');
      var markerPath = join(platformExeDir, markerFile);
      await deleteFile(markerPath);
      expect(File(markerPath).existsSync(), isFalse);

      /// Failing due to GTK issue on github
      if ((Platform.isLinux && !runningOnGithubAction) ||
          Platform.isWindows ||
          Platform.isMacOS) {
        var shell = Shell(workingDirectory: platformExeDir);
        if (Platform.isMacOS) {
          await shell.run(
            'app_build_menu_example.app/Contents/MacOS/app_build_menu_example',
          );
          // The marker is at a different location on MacOS...
        } else if (Platform.isWindows) {
          await shell.run(shellArgument(join('.', appName)));
          expect(File(markerPath).existsSync(), isTrue);
        } else {
          await shell.run(shellArgument(join('.', appName)));
          expect(File(markerPath).existsSync(), isTrue);
        }
      }
    },
    skip: !(Platform.isLinux || Platform.isWindows || Platform.isMacOS),
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

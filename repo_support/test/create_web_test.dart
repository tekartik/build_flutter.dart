import 'dart:io';

import 'package:dev_build/shell.dart';
import 'package:path/path.dart';
import 'package:tekartik_build_menu_flutter/app_build_menu.dart';
import 'package:test/test.dart';

Future<void> main() async {
  var createdOnce = false;
  var path = join('.dart_tool', 'repo_support', 'test', 'app1');
  group(
    'flutter_build',
    () {
      Future<void> createLocalProject({bool? force}) async {
        if (!createdOnce && (force == true || !Directory(path).existsSync())) {
          await createProject(path, platform: buildPlatformWeb);
          createdOnce = true;
        }
      }

      setUpAll(() async {
        await createLocalProject();
      });
      test('build web', () async {
        var shell = Shell(workingDirectory: path);
        await shell.run('flutter build web');
      });
    },
    skip: !isFlutterSupportedSync,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

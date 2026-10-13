import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_build_flutter/build_flutter.dart';
import 'package:tekartik_build_flutter/src/build_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('project', () {
    test(
      'test_create_project',
      () async {
        // Not app1, which build_flutter_test.dart uses while the test files
        // run in parallel.
        var dir = join(
          '.dart_tool',
          'tekartik_build_flutter',
          'test',
          'app_host1',
        );
        await Directory(dir).create(recursive: true);
        await createProject(dir);
        // Try to build but failure is ok
        try {
          await buildProject(dir);
        } catch (e) {
          stderr.writeln('error building project: $e');
        }
      },
      skip: !(Platform.isLinux || Platform.isWindows || Platform.isMacOS),
      timeout: const Timeout(Duration(minutes: 10)),
    );
  });
}

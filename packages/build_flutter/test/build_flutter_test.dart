import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_build_flutter/build_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('project', () {
    test('test_create_project', () async {
      var dir = join('.dart_tool', 'tekartik_build_flutter', 'test', 'app1');
      await Directory(dir).create(recursive: true);
      await createProjectAndCheckoutFromGit(dir);
    });
    test('buildPlatformCurrent', () {
      var platform = buildPlatformCurrent;
      if (Platform.isWindows) {
        expect(platform, 'windows');
        expect(platform, buildPlatformWindows);
      } else if (Platform.isLinux) {
        expect(platform, 'linux');
        expect(platform, buildPlatformLinux);
      } else if (Platform.isMacOS) {
        expect(platform, 'macos');
        expect(platform, buildPlatformMacOS);
      } else {
        throw UnsupportedError('Unsupported platform');
      }
    });
  });
}

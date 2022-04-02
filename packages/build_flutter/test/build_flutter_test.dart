import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_build_flutter/build_flutter.dart';
import 'package:tekartik_build_flutter/src/build_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('project', () {
    test('test_create_project', () async {
      var dir = join('.dart_tool', 'tekartik_build_flutter', 'test', 'app1');
      await Directory(dir).create(recursive: true);
      await createProjectAndCheckoutFromGit(dir);
      // Try to build but failure is ok
      try {
        await buildProject(dir);
      } catch (e) {
        stderr.writeln('error building project: $e');
      }
    },
        skip: !(Platform.isLinux || Platform.isWindows || Platform.isMacOS),
        timeout: const Timeout(Duration(minutes: 10)));
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
    test('getBuildHostSupportedPlatforms', () {
      var platform = buildPlatformCurrent;

      expect(getBuildHostSupportedPlatforms(buildHost: buildHostWindows),
          unorderedEquals([buildPlatformAndroid, buildPlatformWindows]));
      try {
        getBuildHostSupportedPlatforms(buildHost: 'dummy');
        fail('should fail');
      } catch (_) {}

      expect(getBuildHostSupportedPlatforms(buildHost: buildHostLinux),
          unorderedEquals([buildPlatformAndroid, buildPlatformLinux]));

      expect(buildHostsAll, contains(buildHostCurrent));

      expect(
          getBuildHostSupportedPlatforms(buildHost: buildHostMacOS),
          unorderedEquals(
              [buildPlatformAndroid, buildPlatformIOS, buildPlatformMacOS]));
      if (Platform.isWindows) {
        expect(getBuildHostSupportedPlatforms(),
            unorderedEquals([buildPlatformAndroid, buildPlatformWindows]));
        expect(buildHostCurrent, 'windows');
      } else if (Platform.isLinux) {
        expect(getBuildHostSupportedPlatforms(),
            unorderedEquals([buildPlatformAndroid, buildPlatformLinux]));
        expect(buildHostCurrent, 'linux');
      } else if (Platform.isMacOS) {
        expect(platform, buildPlatformMacOS);
        expect(
            getBuildHostSupportedPlatforms(),
            unorderedEquals(
                [buildPlatformAndroid, buildPlatformIOS, buildPlatformMacOS]));
        expect(buildHostCurrent, 'macos');
      }
    });
  });
}

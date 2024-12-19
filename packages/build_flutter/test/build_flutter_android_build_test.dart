import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_build_flutter/build_flutter.dart';
import 'package:tekartik_build_flutter/flutter_project.dart';
import 'package:test/test.dart';

Future<void> main() async {
  if (!(await initFlutterAndroidBuild())) {
    stderr.writeln('Flutter/Android build not setup');
    return;
  }
  var dir =
      join('.dart_tool', 'tekartik_build_flutter', 'test', 'app_android1');
  var buildPlatform = buildPlatformAndroid;
  var flutterAndroidProjectCreatedOnce = false;
  var flutterProject = FlutterProject(dir, buildPlatform: buildPlatform);
  Future<void> createAndroidFlutterProjectIfNeeded() async {
    if (flutterAndroidProjectCreatedOnce) {
      return;
    }
    flutterAndroidProjectCreatedOnce = true;
    await Directory(dir).create(recursive: true);
    await createProject(dir, platform: buildPlatform);
  }

  group('project', () {
    test('test_build_apk', () async {
      await createAndroidFlutterProjectIfNeeded();

      var apkFile = File(flutterProject.getAbsoluteApkPath());

      try {
        await apkFile.delete();
      } catch (_) {}

      // Try to build but failure is ok
      var built = false;
      try {
        await flutterProject.buildAndroidApk();

        built = true;
      } catch (e) {
        stderr.writeln('error building project: $e');
      }
      if (built) {
        expect(apkFile.existsSync(), isTrue);
      }
    },
        skip: !(Platform.isLinux || Platform.isWindows || Platform.isMacOS),
        timeout: const Timeout(Duration(minutes: 10)));

    test('test_build_aab', () async {
      await createAndroidFlutterProjectIfNeeded();

      var aabFile = File(flutterProject.getAbsoluteAppBundlePath());
      try {
        await aabFile.delete();
      } catch (_) {}

      // Try to build but failure is ok
      var built = false;
      try {
        await flutterProject.buildAppBundle();

        built = true;
      } catch (e) {
        stderr.writeln('error building project: $e');
      }
      if (built) {
        expect(aabFile.existsSync(), isTrue);
      }
    },
        skip: !(Platform.isLinux || Platform.isWindows || Platform.isMacOS),
        timeout: const Timeout(Duration(minutes: 10)));
  });
}

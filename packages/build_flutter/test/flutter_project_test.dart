import 'package:fs_shim/utils/path.dart';
import 'package:tekartik_build_flutter/build_flutter.dart';
import 'package:tekartik_build_flutter/src/flutter_project.dart';
import 'package:test/test.dart';

void main() {
  group('flutter_project', () {
    test('getApkPath/getAppBundlePath', () async {
      var flutterProject = FlutterProject('dummy');
      expect(
        flutterProject.getApkPath(),
        toNativePath('build/app/outputs/flutter-apk/app-release.apk'),
      );
      expect(
        flutterProject.getAppBundlePath(),
        toNativePath('build/app/outputs/bundle/release/app-release.aab'),
      );
      flutterProject = FlutterProject('dummy', flavors: ['main']);
      expect(
        flutterProject.getApkPath(),
        toNativePath('build/app/outputs/flutter-apk/app-main-release.apk'),
      );
      expect(
        flutterProject.getAppBundlePath(),
        toNativePath(
          'build/app/outputs/bundle/mainRelease/app-main-release.aab',
        ),
      );
      // 'build/app/outputs/bundle/customRelease/app-custom-release.aab';

      //build/app/outputs/bundle/release/app-release.aab
    });

    test('buildType/buildPlatform', () {
      var flutterProject = FlutterProject('dummy');
      expect(flutterProject.buildType, buildTypeRelease);
      expect(flutterProject.buildPlatform, buildPlatformCurrent);
      flutterProject = FlutterProject(
        'dummy',
        buildType: buildTypeDebug,
        buildPlatform: buildPlatformAndroid,
      );
      expect(flutterProject.buildType, buildTypeDebug);
      expect(flutterProject.buildPlatform, buildPlatformAndroid);
      expect(
        flutterProject.getApkPath(),
        toNativePath('build/app/outputs/flutter-apk/app-debug.apk'),
      );
      expect(
        flutterProject.getAppBundlePath(),
        toNativePath('build/app/outputs/bundle/debug/app-debug.aab'),
      );
    });

    test('flutterProjectAndroidBuildCommand', () {
      expect(
        flutterProjectAndroidBuildCommand(
          FlutterProject('dummy'),
          subcommand: 'apk',
        ),
        'flutter build apk',
      );
      expect(
        flutterProjectAndroidBuildCommand(
          FlutterProject('dummy', buildType: buildTypeDebug, flavors: ['dev']),
          subcommand: 'appbundle',
          target: 'lib/main_dev.dart',
        ),
        'flutter build appbundle --debug --target lib/main_dev.dart'
        ' --flavor dev',
      );
      expect(
        () => flutterProjectAndroidBuildCommand(
          FlutterProject('dummy', flavors: ['a', 'b']),
          subcommand: 'apk',
        ),
        throwsUnsupportedError,
      );
    });
  });
}

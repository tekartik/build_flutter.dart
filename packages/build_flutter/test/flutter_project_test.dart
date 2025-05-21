import 'package:fs_shim/utils/path.dart';
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
  });
}

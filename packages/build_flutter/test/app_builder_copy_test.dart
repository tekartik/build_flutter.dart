@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_android_utils/apk_utils.dart';
import 'package:tekartik_build_flutter/app_builder.dart';
import 'package:test/test.dart';

void main() {
  group('copy built android files', () {
    // A project path relative to the current directory, as tool scripts
    // usually give it (`../my_app`, `apps/my_app`...).
    var top = join('.dart_tool', 'tekartik_build_flutter', 'test', 'copy');
    var appPath = join(top, 'my_app');
    var apkInfo = ApkInfo(
      name: 'com.example.my_app',
      versionName: '1.2.3',
      versionCode: '45',
    );

    setUp(() async {
      await _deleteDir(top);
    });
    tearDown(() async {
      await _deleteDir(top);
    });

    Future<void> writeFile(String path, String content) async {
      var file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
    }

    test('copyApk and copyAab', () async {
      var builder = FlutterAppBuilder(
        context: FlutterAppContext(path: appPath),
      ).defaultFlavorBuilder;
      await writeFile(builder.getApkPath(), 'apk');
      await writeFile(builder.getAabPath(), 'aab');

      await builder.copyApk(apkInfo: apkInfo);
      await builder.copyAab(apkInfo: apkInfo);

      expect(
        File(
          join(appPath, 'deploy', 'apk', 'com.example.my_app_1.2.3_45.apk'),
        ).readAsStringSync(),
        'apk',
      );
      expect(
        File(
          join(appPath, 'deploy', 'aab', 'com.example.my_app_1.2.3_45.aab'),
        ).readAsStringSync(),
        'aab',
      );
    });

    test('copyApk with a flavor', () async {
      var builder = FlutterAppBuilder(
        context: FlutterAppContext(
          path: appPath,
          buildOptions: FlutterAppBuildOptions(flavors: ['dev']),
        ),
      ).flavorBuilder('dev');
      await writeFile(builder.getApkPath(), 'apk dev');

      await builder.copyApk(apkInfo: apkInfo);

      expect(
        File(
          join(appPath, 'deploy', 'apk', 'com.example.my_app_1.2.3_45-dev.apk'),
        ).readAsStringSync(),
        'apk dev',
      );
    });
  });
}

Future<void> _deleteDir(String path) async {
  try {
    await Directory(path).delete(recursive: true);
  } catch (_) {}
}

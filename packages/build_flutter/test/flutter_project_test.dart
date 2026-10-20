import 'dart:io';

import 'package:fs_shim/utils/path.dart';
import 'package:path/path.dart';
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

    test('flutterProjectCreateCommand', () {
      expect(
        flutterProjectCreateCommand(
          FlutterProject('dummy', buildPlatform: buildPlatformLinux),
        ),
        'flutter create --platforms linux .',
      );
      expect(
        flutterProjectCreateCommand(
          FlutterProject('dummy', buildPlatform: buildPlatformAndroid),
          template: 'app',
        ),
        'flutter create --template app --platforms android .',
      );
      expect(
        flutterProjectCreateCommand(
          FlutterProject('dummy', buildPlatform: buildPlatformLinux),
          platform: buildPlatformWeb,
          template: 'plugin',
        ),
        'flutter create --template plugin --platforms web .',
      );
    });

    test('runCreateWorkarounds', () async {
      var tempDir = await Directory.systemTemp.createTemp(
        'flutter_project_test',
      );
      try {
        // Case 1: New project (no lib/main.dart before): keeps widget_test.dart and .metadata
        var newProjectPath = join(tempDir.path, 'new_project');
        var newProject = FlutterProject(newProjectPath);
        await newProject.runCreateWorkarounds(() async {
          await File(
            join(newProjectPath, 'lib', 'main.dart'),
          ).create(recursive: true);
          await File(
            join(newProjectPath, 'test', 'widget_test.dart'),
          ).create(recursive: true);
          await File(join(newProjectPath, '.metadata')).create(recursive: true);
        });
        expect(
          File(join(newProjectPath, 'test', 'widget_test.dart')).existsSync(),
          isTrue,
        );
        expect(File(join(newProjectPath, '.metadata')).existsSync(), isTrue);

        // Case 2: Existing project (lib/main.dart exists before, no widget_test.dart or .metadata before):
        // deletes created widget_test.dart (and empty test/ dir) and .metadata
        var existingProjectPath = join(tempDir.path, 'existing_project');
        await File(
          join(existingProjectPath, 'lib', 'main.dart'),
        ).create(recursive: true);
        var existingProject = FlutterProject(existingProjectPath);
        await existingProject.runCreateWorkarounds(() async {
          await File(
            join(existingProjectPath, 'test', 'widget_test.dart'),
          ).create(recursive: true);
          await File(
            join(existingProjectPath, '.metadata'),
          ).create(recursive: true);
        });
        expect(
          File(
            join(existingProjectPath, 'test', 'widget_test.dart'),
          ).existsSync(),
          isFalse,
        );
        expect(
          Directory(join(existingProjectPath, 'test')).existsSync(),
          isFalse,
        );
        expect(
          File(join(existingProjectPath, '.metadata')).existsSync(),
          isFalse,
        );

        // Case 3: Existing project where widget_test.dart and .metadata already existed before: keeps them
        var keptProjectPath = join(tempDir.path, 'kept_project');
        await File(
          join(keptProjectPath, 'lib', 'main.dart'),
        ).create(recursive: true);
        await File(
          join(keptProjectPath, 'test', 'widget_test.dart'),
        ).create(recursive: true);
        await File(join(keptProjectPath, '.metadata')).create(recursive: true);
        var keptProject = FlutterProject(keptProjectPath);
        await keptProject.runCreateWorkarounds(() async {});
        expect(
          File(join(keptProjectPath, 'test', 'widget_test.dart')).existsSync(),
          isTrue,
        );
        expect(File(join(keptProjectPath, '.metadata')).existsSync(), isTrue);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}

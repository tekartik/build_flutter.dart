@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart' show stringToArguments;
import 'package:tekartik_build_flutter/app_builder.dart';
import 'package:tekartik_build_flutter/build_flutter.dart';
import 'package:tekartik_build_flutter/src/app_builder.dart'
    show flutterAppFlavorHostBuildCommand;
import 'package:test/test.dart';

FlutterAppBuilder _builder({String? module, List<String>? flavors}) =>
    FlutterAppBuilder(
      context: FlutterAppContext(
        path: 'x',
        module: module,
        buildOptions: FlutterAppBuildOptions(flavors: flavors),
      ),
    );

void main() {
  group('FlutterAppContext', () {
    test('copyWith keeps the module', () {
      var context = FlutterAppContext(path: 'x', module: 'custom');
      expect(context.copyWith(path: 'y').module, 'custom');
      expect(context.copyWith(path: 'y').path, 'y');
      expect(FlutterAppContext().copyWith(path: 'y').module, 'app');
    });
  });

  group('FlutterAppFlavorBuilder', () {
    test('getFlutterTargetOption', () {
      var builder = _builder(flavors: ['dev']).flavorBuilder('dev');
      var expected = [
        '--flavor',
        'dev',
        '--dart-define=tekartikAppBuildFlavor=dev',
        '--target',
        'lib/main.dart',
      ];
      expect(stringToArguments(builder.getFlutterTargetOption()), expected);
      expect(
        stringToArguments(builder.getFlutterTargetOption(flavor: 'dev')),
        expected,
      );
      expect(
        stringToArguments(builder.getFlutterTargetOption(flavor: 'prod')),
        [
          '--flavor',
          'prod',
          '--dart-define=tekartikAppBuildFlavor=prod',
          '--target',
          'lib/main.dart',
        ],
      );
      expect(_builder().defaultFlavorBuilder.getFlutterTargetOption(), isEmpty);
    });

    test('android paths, default module', () {
      var builder = _builder().defaultFlavorBuilder;
      expect(
        builder.getApkPath(),
        join(
          'x',
          'build',
          'app',
          'outputs',
          'apk',
          'release',
          'app-release.apk',
        ),
      );
      expect(
        builder.getAabPath(),
        join(
          'x',
          'build',
          'app',
          'outputs',
          'bundle',
          'release',
          'app-release.aab',
        ),
      );
    });

    test('android paths, custom module', () {
      var builder = _builder(module: 'custom').defaultFlavorBuilder;
      expect(
        builder.getApkPath(),
        join(
          'x',
          'build',
          'custom',
          'outputs',
          'apk',
          'release',
          'custom-release.apk',
        ),
      );
      expect(
        builder.getAabPath(),
        join(
          'x',
          'build',
          'custom',
          'outputs',
          'bundle',
          'release',
          'custom-release.aab',
        ),
      );
      builder = _builder(
        module: 'custom',
        flavors: ['dev'],
      ).flavorBuilder('dev');
      expect(
        builder.getApkPath(),
        join(
          'x',
          'build',
          'custom',
          'outputs',
          'apk',
          'dev',
          'release',
          'custom-dev-release.apk',
        ),
      );
      expect(
        builder.getAabPath(),
        join(
          'x',
          'build',
          'custom',
          'outputs',
          'bundle',
          'devRelease',
          'custom-dev-release.aab',
        ),
      );
      expect(
        builder.getAabPath(module: 'other'),
        join(
          'x',
          'build',
          'other',
          'outputs',
          'bundle',
          'devRelease',
          'other-dev-release.aab',
        ),
      );
    });

    test('flutterAppFlavorHostBuildCommand', () async {
      expect(
        flutterAppFlavorHostBuildCommand(_builder().defaultFlavorBuilder),
        'flutter build $buildPlatformCurrent',
      );
      expect(
        stringToArguments(
          flutterAppFlavorHostBuildCommand(
            _builder(flavors: ['dev']).flavorBuilder('dev'),
          ),
        ),
        [
          'flutter',
          'build',
          buildPlatformCurrent,
          '--dart-define=tekartikAppBuildFlavor=dev',
          '--target',
          'lib/main.dart',
        ],
      );
      var dir = await Directory.systemTemp.createTemp('build_flutter_test');
      try {
        await File(
          join(dir.path, 'lib', 'main_dev.dart'),
        ).create(recursive: true);
        var builder = FlutterAppBuilder(
          context: FlutterAppContext(
            path: dir.path,
            buildOptions: FlutterAppBuildOptions(flavors: ['dev']),
          ),
        ).flavorBuilder('dev');
        expect(
          stringToArguments(flutterAppFlavorHostBuildCommand(builder)).last,
          'lib/main_dev.dart',
        );
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}

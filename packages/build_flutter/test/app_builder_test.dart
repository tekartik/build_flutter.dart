@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart' show stringToArguments;
import 'package:tekartik_build_flutter/app_builder.dart';
import 'package:tekartik_build_flutter/build_flutter.dart';
import 'package:tekartik_build_flutter/src/app_builder.dart'
    show flutterAppFlavorBuildCommand, flutterAppFlavorHostBuildCommand;
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

    test('platform entry points', () async {
      var dir = await Directory.systemTemp.createTemp('build_flutter_test');
      Future<void> create(String entryPoint) =>
          File(join(dir.path, entryPoint)).create(recursive: true);
      try {
        FlutterAppFlavorBuilder builder([String? flavor]) => FlutterAppBuilder(
          context: FlutterAppContext(
            path: dir.path,
            buildOptions: FlutterAppBuildOptions(flavors: [?flavor]),
          ),
        ).flavorBuilder(flavor);
        String targetOf(String command) {
          var arguments = stringToArguments(command);
          var index = arguments.indexOf('--target');
          return index < 0 ? 'none' : arguments[index + 1];
        }

        // Nothing: the flutter default.
        expect(
          flutterAppFlavorBuildCommand(builder(), 'apk'),
          'flutter build apk',
        );
        expect(
          flutterAppFlavorHostBuildCommand(builder()),
          'flutter build $buildPlatformCurrent',
        );

        await create('lib/main_android.dart');
        await create('lib/main_ios.dart');
        expect(
          targetOf(flutterAppFlavorBuildCommand(builder(), 'apk')),
          'lib/main_android.dart',
        );
        expect(
          targetOf(flutterAppFlavorBuildCommand(builder(), 'appbundle')),
          'lib/main_android.dart',
        );
        expect(
          targetOf(flutterAppFlavorBuildCommand(builder(), 'ipa')),
          'lib/main_ios.dart',
        );

        // Desktop: main_host, then main_<host platform> first.
        expect(targetOf(flutterAppFlavorHostBuildCommand(builder())), 'none');
        await create('lib/main_host.dart');
        expect(
          targetOf(flutterAppFlavorHostBuildCommand(builder())),
          'lib/main_host.dart',
        );
        await create('lib/main_$buildPlatformCurrent.dart');
        expect(
          targetOf(flutterAppFlavorHostBuildCommand(builder())),
          'lib/main_$buildPlatformCurrent.dart',
        );

        // The flavor entry point first, the platform one otherwise.
        expect(
          stringToArguments(
            flutterAppFlavorBuildCommand(builder('dev'), 'apk'),
          ),
          [
            'flutter',
            'build',
            'apk',
            '--flavor',
            'dev',
            '--dart-define=tekartikAppBuildFlavor=dev',
            '--target',
            'lib/main_android.dart',
          ],
        );
        await create('lib/main_dev.dart');
        expect(
          targetOf(flutterAppFlavorBuildCommand(builder('dev'), 'apk')),
          'lib/main_dev.dart',
        );
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });

  group('entry point', () {
    test('candidates', () {
      expect(flutterProjectEntryPointCandidates(platform: 'web'), [
        'lib/main_web.dart',
      ]);
      expect(flutterProjectEntryPointCandidates(platform: 'linux'), [
        'lib/main_linux.dart',
        'lib/main_host.dart',
      ]);
      expect(
        flutterProjectEntryPointCandidates(platform: 'android', flavor: 'dev'),
        ['lib/main_dev.dart', 'lib/main_android.dart'],
      );
      expect(flutterProjectEntryPointCandidates(), isEmpty);
    });
    test('sub command platform', () {
      expect(flutterBuildSubCommandPlatform('apk'), 'android');
      expect(flutterBuildSubCommandPlatform('appbundle'), 'android');
      expect(flutterBuildSubCommandPlatform('ipa'), 'ios');
      expect(flutterBuildSubCommandPlatform('ios'), 'ios');
      expect(flutterBuildSubCommandPlatform('web'), 'web');
      expect(flutterBuildSubCommandPlatform('linux'), 'linux');
    });
  });
}

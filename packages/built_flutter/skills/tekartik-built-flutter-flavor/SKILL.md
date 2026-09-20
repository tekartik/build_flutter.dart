---
name: tekartik-built-flutter-flavor
description: >-
  Use when a Flutter app must read at runtime the flavor that
  tekartik_build_flutter passed at build time: the tekartik_built_flutter
  package, its envFlavorKey constant, the
  package:tekartik_built_flutter/constant.dart import, and the matching
  --dart-define=<envFlavorKey>=<flavor> flutter build/run option.
---

# Build flavor constant (tekartik_built_flutter)

`tekartik_built_flutter` is a single-constant package: the `--dart-define` key
that `tekartik_build_flutter` uses when it builds or runs a flavored Flutter
app. The build tool writes it, the app reads it back with
`String.fromEnvironment`, and sharing the constant keeps the two sides in sync.

## Guidelines

* Dependency (git, not on pub.dev, inside the `build_flutter.dart` repo):
  ```yaml
  dependencies:
    tekartik_built_flutter:
      git:
        url: https://github.com/tekartik/build_flutter.dart
        path: packages/built_flutter
      version: '>=0.1.0'
  ```
  It has no dependency of its own (pure Dart, works on every platform
  including web). Put it in `dependencies` when the **app** reads the flavor at
  runtime; `dev_dependencies` is enough for a build script that only writes the
  command line.
* The whole public API is one import,
  `package:tekartik_built_flutter/constant.dart` (which exports
  `src/constant.dart`), and one `const String` it defines, `envFlavorKey`
  (currently `'tekartikAppBuildFlavor'`).
* Read the value in a **const** context, otherwise dart2js/AOT compilers do
  not see the `--dart-define`:
  `const appFlavor = String.fromEnvironment(envFlavorKey);` (or with
  `defaultValue: 'dev'`). An empty string means "built with no flavor".
  `bool.hasEnvironment(envFlavorKey)` tells whether the define was passed at
  all.
* Never hardcode the key string: its value changed over time (the package test
  still asserts the older `'flavor'` value), so always reference
  `envFlavorKey`, on both the build side and the app side.
* The build side is automatic when building with `tekartik_build_flutter`:
  `FlutterAppFlavorBuilder` appends
  `--flavor <flavor> --dart-define=<envFlavorKey>="<flavor>" --target
  lib/main_<flavor>.dart` to `flutter build`/`flutter run`
  (desktop targets get the `--dart-define` and `--target` but no `--flavor`).
  When invoking `flutter` yourself, write the same option so the app reads the
  same value. See the `tekartik-build-flutter-app-builder` skill.
* Because the flavor is a compile-time constant, it cannot be changed at
  runtime and switching flavor means rebuilding. Use it to pick a
  configuration (firebase project, api url, app title), not as mutable state.

## Examples

### Read the flavor in the app

```dart
import 'package:tekartik_built_flutter/constant.dart';

/// Flavor the app was built with, empty when built without one.
const appFlavor = String.fromEnvironment(envFlavorKey);

void main() {
  print(appFlavor.isEmpty ? 'no flavor' : 'flavor: $appFlavor');
}
```

### Per-flavor configuration with a default

```dart
import 'package:tekartik_built_flutter/constant.dart';

const appFlavor = String.fromEnvironment(envFlavorKey, defaultValue: 'dev');

class AppConfig {
  final String apiUrl;

  const AppConfig({required this.apiUrl});

  static const dev = AppConfig(apiUrl: 'https://dev.example.com');
  static const prod = AppConfig(apiUrl: 'https://example.com');

  static AppConfig get current => appFlavor == 'prod' ? prod : dev;
}

void main() {
  print('api: ${AppConfig.current.apiUrl} ($appFlavor)');
}
```

### Build command line that matches the constant

```dart
import 'dart:io';

import 'package:tekartik_built_flutter/constant.dart';

/// `flutter build apk` for [flavor], defining the flavor the app can read.
Future<void> buildFlavor(String flavor, {String path = '.'}) async {
  var result = await Process.run('flutter', [
    'build',
    'apk',
    '--flavor',
    flavor,
    '--dart-define=$envFlavorKey=$flavor',
    '--target',
    'lib/main_$flavor.dart',
  ], workingDirectory: path);
  stdout.write(result.stdout);
}
```

## Common mistakes

* Reading the define without `const`
  (`var flavor = String.fromEnvironment(envFlavorKey);`): unreliable, empty on
  some compilers.
* Writing the literal `'flavor'` or `'tekartikAppBuildFlavor'` in the build
  command instead of `envFlavorKey`.
* Expecting `--flavor dev` alone to be visible to Dart code: only the
  `--dart-define` reaches `String.fromEnvironment`.
* Expecting the flavor to be readable on a desktop build that was run without
  the `--dart-define` option.

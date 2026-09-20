---
name: tekartik-build-flutter-project
description: >-
  Use when a Dart build script must create, build, locate or run a Flutter
  project from the command line with tekartik_build_flutter: createProject,
  createProjectAndCheckoutFromGit, hasPlatformProject, buildProject,
  runBuiltProject, getBuildProjectAppPath, getBuildProjectExePath,
  getBuildProjectAppFilename, platformExeDir, buildPlatformCurrent,
  buildPlatformAndroid/Ios/Web/Linux/MacOS/Windows, buildHostLinux,
  buildPlatformsAll, getBuildHostSupportedPlatforms, FlutterProject apk/aab
  paths, initFlutterAndroidBuild, getFlutterDevices and FlutterDevice.
---

# Flutter project, platforms and devices (tekartik_build_flutter)

`tekartik_build_flutter` is a Dart-only tool library (no Flutter SDK
dependency) that shells out to `flutter` to create a project for a given
platform, build it, find the produced executable/apk/aab and list the attached
devices. This skill covers the low-level entry points; the flavor/deploy/
publish pipeline is in
[../tekartik-build-flutter-app-builder/SKILL.md](../tekartik-build-flutter-app-builder/SKILL.md).

## Guidelines

* Dev-time tool, `flutter` must be on the `PATH`. Not on pub.dev
  (`publish_to: none`), depend on it with git:
  ```yaml
  dev_dependencies:
    tekartik_build_flutter:
      git:
        url: https://github.com/tekartik/build_flutter.dart
        path: packages/build_flutter
      version: '>=1.0.2'
  ```
* Imports: `package:tekartik_build_flutter/build_flutter.dart` (project
  create/build/run + all the platform constants, it re-exports
  `build_flutter_common.dart`), `package:tekartik_build_flutter/
  flutter_project.dart` (`FlutterProject`, `initFlutterAndroidBuild`),
  `package:tekartik_build_flutter/flutter_devices.dart`
  (`getFlutterDevices`), `package:tekartik_build_flutter/
  build_flutter_common.dart` when only the constants are needed.
* Platform vs host: `buildPlatformAndroid`, `buildPlatformIOS`,
  `buildPlatformWeb`, `buildPlatformLinux`, `buildPlatformWindows`,
  `buildPlatformMacOS` are plain `String` vars (not an enum), grouped in
  `buildPlatformsAll` and `buildPlatformsDesktopAll`. Hosts are
  `buildHostLinux` / `buildHostWindows` / `buildHostMacOS` (`buildHostsAll`).
  `buildPlatformCurrent` is the **desktop** target of the current host (it
  throws `UnsupportedError` outside linux/windows/macos); the host name itself
  is internal, compare `buildPlatformCurrent` with `buildHostLinux` and
  friends, they share the same values.
  `buildHostSupportedPlatforms` (and
  `getBuildHostSupportedPlatforms({String? buildHost})`, which returns `null`
  for an unknown host) gives what can be built here: linux/windows →
  `[<host>, android, web]`, macos → `[macos, android, ios, web]`.
  Prefer `getBuildHostSupportedPlatforms()` over the deprecated
  `buildSupportedPlatforms`.
* `createProject(path, {platform})` is destructive by design: it deletes
  `<path>/<platform>`, creates `path`, runs `flutter config
  --enable-<platform>-desktop` for desktop platforms and then
  `flutter create --platforms <platform> .`. `platform` defaults to
  `buildPlatformCurrent`. Guard it with `hasPlatformProject(path,
  platform: ...)` when the project folder must be kept.
  `createProjectAndCheckoutFromGit(path, {platform})` does the same then
  `git checkout <platform>` in `path` (errors swallowed), which restores the
  committed platform files of a project that keeps them in git. The same thing
  is available as a CLI:
  `dart run tekartik_build_flutter:create_project_and_checkout_from_git [<dir>]
  [-p <platform>] [--platforms linux,windows]`.
* `buildProject(path, {target, platform, flavor})` runs `flutter build` with
  the right subcommand: `apk` for android, `ipa` for ios, the platform name
  otherwise (`web`, `linux`...). `--flavor` is only passed for android.
* Locating the result of a desktop build: `platformExeDir` is the
  host-specific release folder (`build/linux/x64/release/bundle`,
  `build/windows/x64/runner/Release`, `build/macos/Build/Products/Release`),
  `getBuildProjectAppFilename(path)` is the pubspec `name` with the
  host suffix (`.exe` on windows, `.app` on macos),
  `getBuildProjectAppPath(path)` is the app (the `.app` bundle on macos) and
  `getBuildProjectExePath(path)` the runnable executable (inside the bundle on
  macos). Both throw a `StateError` when the project was not built.
* `runBuiltProject(path, {bool? console})` launches the release build; on
  macos it uses `open -na` on the bundle unless `console` is true (use
  `console: true` in tests to see the output and wait for the exit).
* `deleteDir(path)` / `deleteFile(path)` are best-effort helpers (recursive,
  all errors swallowed) for build scripts.
* `FlutterProject(path, {flavors, androidModule, buildPlatform, buildType})`
  is the small android-oriented alternative: it computes artifact paths from
  the naming convention without touching the filesystem.
  `getApkPath()` → `build/app/outputs/flutter-apk/app-release.apk` (no flavor)
  or `build/app/outputs/flutter-apk/app-main-release.apk` for
  `flavors: ['main']`; `getAppBundlePath()` →
  `build/app/outputs/bundle/release/app-release.aab` or
  `build/app/outputs/bundle/mainRelease/app-main-release.aab`.
  `getAbsolutePath()`, `getAbsoluteApkPath()`, `getAbsoluteAppBundlePath()`
  (not the deprecated `getAbsoluteAabPath()`) and
  `getAbsolutePathFromRelative(relative)` give absolute paths;
  `buildAndroidApk({target})` and `buildAppBundle({target})` build, adding
  `--flavor` when a single flavor is declared (`flavor` is the single flavor
  or `null`, `hasFlavors` tells whether any was declared).
  Caveat: the `buildPlatform` and `buildType` constructor arguments are
  currently ignored — a `FlutterProject` is always
  `buildPlatform: buildPlatformCurrent`, `buildType: buildTypeRelease`.
  `androidModule` defaults to `defaultAppAndroidModule` (`'app'`).
* `initFlutterAndroidBuild({int? sdkVersion})` resolves the Android SDK build
  tools and initializes the environment; it returns `false` instead of
  throwing when no SDK is available — use it as an early guard in android
  build scripts and tests.
* `getFlutterDevices()` parses `flutter devices --machine` into
  `List<FlutterDevice>` (`cv` models: `name`, `id`, `isSupported`,
  `targetPlatform`, `emulator`, `sdk`, `capabilities` — read a field with
  `.v`, e.g. `device.id.v`). Filter with the list extension getters
  `.supported`, `.android`, `.ios`, print with `.toJsonPretty()`, and test a
  single device with `device.isAndroid` / `device.isIos`.
  `FlutterDeviceCapabilities` models the `capabilities` map
  (`hotReload`, `hotRestart`, `screenshot`, `fastStart`, `flutterExit`,
  `hardwareRendering`, `startPaused`).

## Examples

### Create and build the project for the current desktop host, then run it

```dart
import 'package:tekartik_build_flutter/build_flutter.dart';

Future<void> main() async {
  var dir = '.local/my_app';
  if (!hasPlatformProject(dir)) {
    await createProject(dir); // platform: buildPlatformCurrent
  }
  await buildProject(dir);
  print('built ${await getBuildProjectExePath(dir)}');
  await runBuiltProject(dir, console: true);
}
```

### Build every platform supported by this host

```dart
import 'package:tekartik_build_flutter/build_flutter.dart';

Future<void> main() async {
  var dir = '.';
  print('desktop target: $buildPlatformCurrent');
  for (var platform in buildHostSupportedPlatforms) {
    if (platform == buildPlatformWeb) {
      continue;
    }
    print('building $platform');
    await buildProject(dir, platform: platform);
  }
}
```

### Android apk/aab paths with a flavor

```dart
import 'dart:io';

import 'package:tekartik_build_flutter/build_flutter.dart';
import 'package:tekartik_build_flutter/flutter_project.dart';

Future<void> main() async {
  if (!await initFlutterAndroidBuild()) {
    stderr.writeln('android build not setup');
    return;
  }
  var project = FlutterProject('my_app', flavors: ['main']);
  await project.buildAndroidApk(); // flutter build apk --flavor main
  await project.buildAppBundle();
  print(project.getAbsoluteApkPath()); // .../build/app/outputs/flutter-apk/app-main-release.apk
  print(project.getAbsoluteAppBundlePath());
  print(buildPlatformAndroid);
}
```

### List the connected devices

```dart
import 'dart:io';

import 'package:tekartik_build_flutter/flutter_devices.dart';

Future<void> main() async {
  var devices = await getFlutterDevices();
  stdout.writeln(devices.toJsonPretty());
  var android = devices.android.supported.firstOrNull;
  if (android != null) {
    stdout.writeln('android device: ${android.id.v} (${android.name.v})');
  }
}
```

### Recreate the platform folders from git before a release build

```dart
import 'package:tekartik_build_flutter/build_flutter.dart';

Future<void> main(List<String> args) async {
  var dir = args.isNotEmpty ? args.first : '.';
  for (var platform in [buildPlatformLinux, buildPlatformAndroid]) {
    await createProjectAndCheckoutFromGit(dir, platform: platform);
  }
}
```

## Common mistakes

* Calling `createProject` on an existing app without checking
  `hasPlatformProject`: the platform folder is deleted and regenerated.
* Expecting `FlutterProject(..., buildType: buildTypeDebug)` to build debug:
  the argument is ignored, only release paths are produced.
* Reading a `FlutterDevice` field directly instead of through `.v`
  (`device.id` is a `CvField<String>`, `device.id.v` is the `String?`).
* Assuming `buildPlatformCurrent` covers mobile: it is the desktop target of
  the current host; use `buildHostSupportedPlatforms` to know what else can be
  built.
* Running any of this on a host other than linux/windows/macos:
  `buildPlatformCurrent` throws `UnsupportedError`.

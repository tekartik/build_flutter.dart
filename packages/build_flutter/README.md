# tekartik_build_flutter

Build scripts for Flutter apps, in Dart: create a platform folder, build the
android apk/aab, the ios ipa or the desktop release of each flavor, copy the
results to a `deploy/` folder under versioned names, upload the bundle to the
Play Store, list the devices and patch the macOS entitlements.

It starts `flutter` (and `adb`, `pod`, `git`) processes with process_run, so
it is a Dart VM tool for `tool/` scripts (Linux, macOS, Windows) and has no
Flutter SDK dependency itself: never import it from the app.

## Getting started

A git dependency (not on pub.dev), in the `dev_dependencies` of the app or of
a separate tool package:

```yaml
dev_dependencies:
  tekartik_build_flutter:
    git:
      url: https://github.com/tekartik/build_flutter.dart
      path: packages/build_flutter
```

`flutter` must be on the PATH (`adb` for the device helpers, the Android SDK
for android builds, Xcode and `pod` for ios).

```dart
// tool/build.dart, run from the app: dart run tool/build.dart
import 'package:tekartik_build_flutter/app_builder.dart';

Future<void> main() async {
  var builder = FlutterAppBuilder(
    context: FlutterAppContext(
      path: '.', // the app, relative to the current directory
      buildOptions: FlutterAppBuildOptions(flavors: ['dev', 'prod']),
    ),
  );
  for (var flavorBuilder in builder.flavorBuilders) {
    // flutter build apk + appbundle --flavor <flavor>, then copy both to
    // deploy/apk and deploy/aab as <package>_<version>_<code>-<flavor>.apk
    var apkInfo = await flavorBuilder.buildAndroidAndCopy();
    print(await flavorBuilder.getApkDeployedPath(apkInfo: apkInfo));
  }
}
```

[example/main.dart](example/main.dart) also builds the desktop release of the
host and prints the paths without building.

## Libraries

| Import | Holds |
| --- | --- |
| `package:tekartik_build_flutter/app_builder.dart` | `FlutterAppBuilder`, `FlutterAppFlavorBuilder` (build, copy, publish, host builds), `FlutterAppContext`, `FlutterAppBuildOptions` |
| `package:tekartik_build_flutter/app_publisher.dart` | the Play Store and App Store publishers (`initAndroidPublisherClient`, `PublishOptions`...) |
| `package:tekartik_build_flutter/build_flutter.dart` | `createProject`, `buildProject`, `runBuiltProject`, the built app paths, the platform constants, the entry points |
| `package:tekartik_build_flutter/flutter_project.dart` | `FlutterProject` (android apk/aab of one project), `initFlutterAndroidBuild` |
| `package:tekartik_build_flutter/flutter_devices.dart` | `getFlutterDevices` (`flutter devices --machine`) |

Command line: `dart run tekartik_build_flutter:create_project_and_checkout_from_git
[<dir>] [-p <platform>]` re-creates a platform folder and checks its tracked
files out of git (`--help` prints the usage only).

## Conventions

* Entry points: `lib/main_<flavor>.dart`, then `lib/main_<platform>.dart`
  (`main_android`, `main_ios`, `main_linux`...), then `lib/main_host.dart` on
  desktop, when they exist; `lib/main.dart` otherwise.
* A flavor gets `--flavor` on android only, and
  `--dart-define=tekartikAppBuildFlavor=<flavor>` everywhere (read it back with
  `envFlavorKey` of `tekartik_built_flutter`).
* `getApkPath()` / `getAabPath()` follow the gradle names
  (`build/app/outputs/apk/dev/release/app-dev-release.apk`,
  `build/app/outputs/bundle/devRelease/app-dev-release.aab`), starting with
  the project `path`.

## Pitfalls

* A relative `path` is relative to the current directory of the script, not
  to the script file.
* `createProject` deletes `<path>/<platform>` before running `flutter
  create`: check `hasPlatformProject` first, or use
  `createProjectAndCheckoutFromGit` when the platform folder is in git.
* `getApkInfo()`, `copyApk()`, `androidPublish()` read the built apk: build
  it first (`buildAndroidAndCopy()` does everything).
* `flavorBuilder()` without a flavor on a builder that declares flavors (or
  an unknown flavor) throws a `StateError`.
* `buildPlatformCurrent` is the desktop platform of the host; it throws on
  any other host.

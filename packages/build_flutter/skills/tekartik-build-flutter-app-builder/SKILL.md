---
name: tekartik-build-flutter-app-builder
description: >-
  Use when scripting the release build, deploy and store publication of a
  Flutter app with tekartik_build_flutter: FlutterAppBuilder,
  FlutterAppContext, FlutterAppBuildOptions, FlutterAppFlavorBuilder,
  flavorBuilder/defaultFlavorBuilder, buildAndroidApk, buildAndroidAab,
  buildIosIpa, buildAndroidAndCopy, copyApk/copyAab, androidPublish,
  androidBuildAndPublish, buildHost/runHost desktop builds, iosPodInstall,
  macosDisableSandbox, flutterProjectClean, the app_builder.dart and
  app_publisher.dart imports, flavors and --dart-define flavor conventions.
---

# Flutter app build/deploy/publish pipeline (tekartik_build_flutter)

`tekartik_build_flutter` is a Dart-only (no Flutter SDK dependency) tool
library that drives the `flutter`, `adb`, `pod` and Play Store CLIs/APIs from a
build script. `FlutterAppBuilder` + `FlutterAppFlavorBuilder` are the
high-level pipeline: build per flavor, copy the artifacts to a `deploy/`
folder with versioned names, then upload the bundle to the Play Store.

## Guidelines

* It is a dev/CI-time tool: put it in `dev_dependencies`, never import it from
  app runtime code. It shells out, so `flutter` (and `adb`/`pod` for the
  Android/iOS helpers) must be on the `PATH`.
  ```yaml
  dev_dependencies:
    tekartik_build_flutter:
      git:
        url: https://github.com/tekartik/build_flutter.dart
        path: packages/build_flutter
      version: '>=1.0.2'
  ```
  Not on pub.dev (`publish_to: none`), so always a `git:` dependency.
* Imports: `package:tekartik_build_flutter/app_builder.dart` for the builders
  (it also re-exports `CommonAppBuilder`/`CommonAppBuilderExt` from
  `tekartik_common_build`), `package:tekartik_build_flutter/app_publisher.dart`
  for the Play Store / App Store API (`initAndroidPublisherClient`,
  `AndroidPublisherClient`, `PublishOptions`, `publishTrackInternal`...).
  For low-level `createProject`/`buildProject`/`FlutterProject`/device
  helpers see [../tekartik-build-flutter-project/SKILL.md](../tekartik-build-flutter-project/SKILL.md).
* Build the object graph top-down:
  `FlutterAppBuilder(context: FlutterAppContext(path: '.', module: 'app',
  buildOptions: FlutterAppBuildOptions(flavors: ['dev', 'prod'])),
  deployPath: 'deploy')`. `path` defaults to `'.'` (the app checkout),
  `module` to `'app'` (the android gradle module), `deployPath` to `'deploy'`.
* Get a per-flavor builder with `builder.flavorBuilder('dev')`,
  `builder.defaultFlavorBuilder` (flavor `null`) or iterate
  `builder.flavorBuilders` (one per declared flavor, or a single default
  builder when `flavors` is empty). `flavorBuilder(x)` throws a `StateError`
  when `x` is not a declared flavor — including `flavorBuilder()` on a builder
  that declares flavors.
* Flavor conventions applied by `FlutterAppFlavorBuilder`
  (`getFlutterTargetOption()`): the flutter command gets
  `--flavor <flavor> --dart-define=<envFlavorKey>="<flavor>"
  --target lib/main_<flavor>.dart` (falling back to `lib/main.dart` when that
  entry point does not exist). `envFlavorKey` is the constant of
  `tekartik_built_flutter` (`package:tekartik_built_flutter/constant.dart`);
  read the flavor back at runtime with
  `String.fromEnvironment(envFlavorKey)`. `flavorName` is `flavor ?? 'main'`.
* Build actions on a flavor builder: `buildAndroidApk()` (`flutter build
  apk`), `buildAndroidAab()` (`appbundle`), `buildIosIpa()` (`ipa`),
  `build('<any flutter build subcommand>')` for the rest (e.g. `'web'`),
  `clean()` (`flutter clean`, same as top-level `flutterProjectClean(path)`),
  and `run({String? deviceId, bool? release})` for `flutter run`. Every
  `build*` first calls `generateVersionIfNeeded()`.
* Artifact paths are computed from the gradle naming convention (relative to
  the app `path`, no filesystem lookup). With flavor `dev` and module `app`:
  `getApkPath()` → `build/app/outputs/apk/dev/release/app-dev-release.apk`,
  `getAabPath()` → `build/app/outputs/bundle/devRelease/app-dev-release.aab`;
  with no flavor: `build/app/outputs/apk/release/app-release.apk` and
  `build/app/outputs/bundle/release/app-release.aab`.
  `FlutterAppFlavorBuilder.flavorToPath('dev-release')` is the
  lower-camel-case join used for the bundle folder (`'devRelease'`).
* Deploy: `buildAndroidAndCopy()` builds apk + aab, reads the apk info and
  copies both to `apksDeployPath` (`deploy/apk`) and `aabsDeployPath`
  (`deploy/aab`) under `getDeployBaseName()` =
  `<packageName>_<versionName>_<versionCode>[-<flavor>]`. `copyAndroid()`
  copies without rebuilding, `copyApk()` / `copyAab()` do one artifact,
  `getApkDeployedPath()` returns the destination. `getApkInfo()` parses the
  **built** apk and throws a `StateError` when it is missing, so build first.
  Do not use the deprecated `apkDeployPath` / `aabDeployPath` /
  `defaultFlavorBuild` getters.
* Play Store: authenticate once with
  `initAndroidPublisherClient(serviceAccount: <decoded json map>)`, then
  `flavorBuilder.androidBuildAndPublish(client: client, publishOptions:
  PublishOptions(track: publishTrackInternal))` (build + copy + upload) or
  `androidPublish(client: ...)` alone when the aab is already built. Publish
  uploads the **aab** and takes the package name/version code from the apk
  info, so the apk must be built too.
* Desktop (host) platform: `createHostProject({bool? force})` runs
  `flutter create` for the current host only when the platform folder is
  missing, `buildHostOnly()` builds the release, `buildHost()` builds then
  `copyBuiltHostToDeploy()` (to `hostDeployPath`, `deploy/<platform>` plus the
  flavor suffix, destination deleted first), `runHostRelease()` launches the
  built release and `runHost()` runs it in debug. Desktop projects get no
  `--flavor` (only the `--dart-define` and `--target`).
* iOS/macOS helpers live on `FlutterAppBuilder` (not the flavor builder):
  `iosBuildConfigOnly()` (`flutter build ios --config-only`), `iosCleanPods()`
  (deletes `Pods/`, `.symlinks/`, `Podfile.lock`), `iosPodInstall({bool?
  repoUpdate})`, and `macosAllowInternetAccess({bool? server})`,
  `macosDisableSandbox()`, `macosEnableSandbox()` which patch the macOS
  entitlements files.
* Version helpers come from the re-exported `CommonAppBuilderExt` extension
  and work on both builders: `generateVersion()`,
  `generateVersionIfNeeded()`, `bumpVersion(patch: true)`.
* Android device actions need a connected device (they pick the first
  supported android device from `getFlutterDevices()` and print to stderr when
  there is none): `installDeployedApk()` (`adb install`) and
  `runBuiltAndroidApk(activity: '.MainActivity')` (`adb shell am start`).

## Examples

### Build and deploy every flavor

```dart
import 'package:tekartik_build_flutter/app_builder.dart';

Future<void> main() async {
  var builder = FlutterAppBuilder(
    context: FlutterAppContext(
      path: '.',
      buildOptions: FlutterAppBuildOptions(flavors: ['dev', 'prod']),
    ),
  );
  for (var flavorBuilder in builder.flavorBuilders) {
    print('building ${flavorBuilder.flavorName}');
    await flavorBuilder.clean();
    var apkInfo = await flavorBuilder.buildAndroidAndCopy();
    print('deployed ${await flavorBuilder.getApkDeployedPath(apkInfo: apkInfo)}');
  }
}
```

### Build and publish one flavor to the Play Store internal track

```dart
import 'dart:convert';
import 'dart:io';

import 'package:tekartik_build_flutter/app_builder.dart';
import 'package:tekartik_build_flutter/app_publisher.dart';

Future<void> main() async {
  var serviceAccount =
      jsonDecode(await File('.local/play_service_account.json').readAsString())
          as Map;
  var client = await initAndroidPublisherClient(serviceAccount: serviceAccount);
  var builder = FlutterAppBuilder(
    context: FlutterAppContext(
      buildOptions: FlutterAppBuildOptions(flavors: ['prod']),
    ),
  );
  await builder.flavorBuilder('prod').androidBuildAndPublish(
    client: client,
    publishOptions: PublishOptions(track: publishTrackInternal),
  );
}
```

### Desktop release: build, copy to deploy, run

```dart
import 'package:tekartik_build_flutter/app_builder.dart';

Future<void> main(List<String> args) async {
  var builder = FlutterAppBuilder(context: FlutterAppContext(path: '.'));
  var flavorBuilder = builder.defaultFlavorBuilder;
  await flavorBuilder.buildHost(); // creates the platform project if needed
  print('deployed in ${flavorBuilder.hostDeployPath}');
  await flavorBuilder.runHostRelease();
}
```

### iOS pods refresh then ipa build

```dart
import 'package:tekartik_build_flutter/app_builder.dart';

Future<void> main() async {
  var builder = FlutterAppBuilder(
    context: FlutterAppContext(
      path: 'my_app',
      buildOptions: FlutterAppBuildOptions(flavors: ['prod']),
    ),
  );
  await builder.iosCleanPods();
  await builder.iosBuildConfigOnly();
  await builder.iosPodInstall(repoUpdate: true);
  await builder.flavorBuilder('prod').buildIosIpa();
}
```

### Install and start the deployed apk on a device

```dart
import 'package:tekartik_build_flutter/app_builder.dart';

Future<void> main() async {
  var flavorBuilder = FlutterAppBuilder(
    context: FlutterAppContext(),
  ).defaultFlavorBuilder;
  await flavorBuilder.buildAndroidAndCopy();
  await flavorBuilder.installDeployedApk();
  await flavorBuilder.runBuiltAndroidApk(activity: '.MainActivity');
}
```

## Common mistakes

* Calling `flavorBuilder()` with no argument on a builder that declares
  flavors (or `flavorBuilder('dev')` when none are declared): `StateError`.
* Calling `getApkInfo()`, `copyApk()` or `androidPublish()` before the apk/aab
  are built.
* Expecting `--flavor` on desktop/web builds: only android (and the flavor
  `--dart-define`/`--target`) uses it.
* Adding the package to `dependencies` of a Flutter app: it is a build-time
  Dart tool, keep it in `dev_dependencies` (or a separate tool package).

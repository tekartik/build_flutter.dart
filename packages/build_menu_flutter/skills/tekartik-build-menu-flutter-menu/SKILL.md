---
name: tekartik-build-menu-flutter-menu
description: >-
  Use when building an interactive console build menu for a Flutter app with
  tekartik_build_menu_flutter: the fbm command, menuAppContent,
  menuFlutterAppContent, menuFlutterAppFlavorContent,
  menuFlutterAppFlavorPublish, menuFdmContent, tkFlutterDeviceIdVar, the
  app_build_menu.dart import that re-exports mainMenuConsole/menu/item/write
  from dev_build, FlutterAppBuilder/FlutterAppContext/FlutterAppBuildOptions
  and the Play Store AndroidPublisherClient.
---

# Flutter build menu (tekartik_build_menu_flutter)

`tekartik_build_menu_flutter` turns the `tekartik_build_flutter` builders into
an interactive console menu (`dev_build`'s menu engine): create platform
projects, build/run per flavor, copy apk/aab to `deploy/`, inspect signatures
and publish to the Play Store, all from a small `tool/` script or from the
bundled `fbm` command.

## Guidelines

* Dev-time tool. Not on pub.dev, depend on it with git:
  ```yaml
  dev_dependencies:
    tekartik_build_menu_flutter:
      git:
        url: https://github.com/tekartik/build_flutter.dart
        path: packages/build_menu_flutter
      version: '>=0.3.0'
  ```
  Or use it without touching the app pubspec: activate the `fbm` executable
  from a checkout (`flutter pub global activate -s path .` in
  `packages/build_menu_flutter`, as the package README says), then run
  `fbm [--flavors dev,prod] [<app path>]` in the app folder (`fbm -h` for the
  usage; the path defaults to the current directory).
* One import gives everything:
  `package:tekartik_build_menu_flutter/app_build_menu.dart`. It re-exports the
  menu primitives (`mainMenuConsole`, `menu`, `item`, `enter`, `write`,
  `prompt`, `showMenu`, `popMenu` from `dev_build`, `mainMenu` from
  `tekartik_app_dev_menu`), the whole `tekartik_build_flutter` surface
  (`FlutterAppBuilder`, `FlutterAppContext`, `FlutterAppBuildOptions`,
  `FlutterAppFlavorBuilder`, `createProject`, `buildProject`,
  `runBuiltProject`, `buildPlatformCurrent`, `buildHostSupportedPlatforms`,
  `getFlutterDevices`, `FlutterProject`...), the Play Store API
  (`AndroidPublisherClient`, `AndroidPublisher`, `initAndroidPublisherClient`,
  `publishTrackInternal`, `publishTrackProduction`) and
  `initAndroidBuildEnvironment` from `tekartik_android_utils`.
  Do not import `dev_build/menu/menu.dart` or `tekartik_build_flutter`
  separately in a script that already imports `app_build_menu.dart`.
* A menu script is a `main` that calls `mainMenuConsole(arguments, () { ... })`
  and declares content inside the callback. Put it in `tool/` (e.g.
  `tool/build_menu.dart`) and run it with `dart run tool/build_menu.dart`;
  passing item names as arguments runs them without the interactive prompt
  (that is how CI reuses the menu).
* `menuAppContent({String path = '.', List<String>? flavors,
  AndroidPublisherClient? androidPublisherClient})` is the one-liner that
  builds the whole menu (project/flavors/build/run/web sections) from a path.
  It is the `fbm` entry point; prefer `menuFlutterAppContent(builder: ...)`
  when the `FlutterAppBuilder` needs a custom `deployPath` or `module`.
* `menuFlutterAppContent({required FlutterAppBuilder builder,
  AndroidPublisherClient? androidPublisherClient})` declares: flavor
  selection, a `project` menu (create the platform projects, ios pods, macos
  entitlements/sandbox), the per-flavor menus, a `build` menu (one entry per
  `buildHostSupportedPlatforms`), a `run` menu, plus `run_ci`, `pub_get`,
  `pub_upgrade`, `flutter clean` and a free `prompt` item.
* `menuFlutterAppFlavorContent({required FlutterAppFlavorBuilder
  flavorBuilder, AndroidPublisherClient? androidPublisherClient})` is the
  per-flavor menu (run on device, clean, ios ipa, android aab/apk/sha1/apkinfo
  /copy, host desktop build/run/deploy). Call it directly to build a menu
  around a single flavor builder.
* `menuFlutterAppFlavorPublish({required FlutterAppFlavorBuilder
  flavorBuilder, required AndroidPublisherClient client})` is the Play Store
  submenu: list bundles, list tracks, bundles per track, promote internal to
  production, publish internal. It reads the apk info on `enter`, so the apk
  must be built first. The publish items only appear in the generated menus
  when an `androidPublisherClient` is passed; build one with
  `initAndroidPublisherClient(serviceAccount: <decoded service account json>)`.
* Device selection: `menuFdmContent()` declares the device menu (select from
  `getFlutterDevices()`, show and clear the selection) and
  `tkFlutterDeviceIdVar` is the `KeyValue` holding the choice in the
  `TK_FLUTTER_DEVICE_ID` var: `tkFlutterDeviceIdVar.value` (`String?`),
  `await tkFlutterDeviceIdVar.set(id)`, `await tkFlutterDeviceIdVar.delete()`.
  The flavor `run` items pass that id to `flavorBuilder.run(deviceId: ...)`.
* Android items that need the SDK (apk info, sha1, publish) await an
  `initAndroidBuildEnvironment()` future first; do the same
  (`var androidReady = initAndroidBuildEnvironment();` at top level, then
  `await androidReady` in the item) when adding custom android items.
* `flutter` (and `adb`/`pod`/the Android SDK for the android items) must be on
  the `PATH`: every item shells out. The menu is for a Flutter app checkout,
  not for the tool package itself.

## Examples

### Minimal build menu for an app with two flavors

```dart
import 'package:tekartik_build_menu_flutter/app_build_menu.dart';

Future<void> main(List<String> arguments) async {
  mainMenuConsole(arguments, () {
    menuAppContent(path: '.', flavors: ['dev', 'prod']);
  });
}
```

### Custom builder (deploy path, module) plus extra items

```dart
import 'package:tekartik_build_menu_flutter/app_build_menu.dart';

Future<void> main(List<String> arguments) async {
  var builder = FlutterAppBuilder(
    deployPath: '.local/deploy',
    context: FlutterAppContext(
      path: 'my_app',
      buildOptions: FlutterAppBuildOptions(flavors: ['dev', 'prod']),
    ),
  );
  mainMenuConsole(arguments, () {
    menuFlutterAppContent(builder: builder);
    menu('extra', () {
      item('bump patch version', () async {
        await builder.bumpVersion(patch: true);
      });
      item('list devices', () async {
        write((await getFlutterDevices()).toJsonPretty());
      });
    });
  });
}
```

### Menu with the Play Store publish items

```dart
import 'dart:convert';
import 'dart:io';

import 'package:tekartik_build_menu_flutter/app_build_menu.dart';

Future<void> main(List<String> arguments) async {
  var serviceAccount =
      jsonDecode(await File('.local/play_service_account.json').readAsString())
          as Map;
  var client = await initAndroidPublisherClient(serviceAccount: serviceAccount);
  mainMenuConsole(arguments, () {
    menuAppContent(
      path: '.',
      flavors: ['prod'],
      androidPublisherClient: client,
    );
  });
}
```

### Single flavor menu plus its own publish submenu

```dart
import 'dart:convert';
import 'dart:io';

import 'package:tekartik_build_menu_flutter/app_build_menu.dart';

Future<void> main(List<String> arguments) async {
  var client = await initAndroidPublisherClient(
    serviceAccount:
        jsonDecode(await File('.local/play.json').readAsString()) as Map,
  );
  var flavorBuilder = FlutterAppBuilder(
    context: FlutterAppContext(
      buildOptions: FlutterAppBuildOptions(flavors: ['prod']),
    ),
  ).flavorBuilder('prod');
  mainMenuConsole(arguments, () {
    menuFlutterAppFlavorContent(flavorBuilder: flavorBuilder);
    menu('play store', () {
      menuFlutterAppFlavorPublish(flavorBuilder: flavorBuilder, client: client);
    });
  });
}
```

### Device selection menu only (fdm style)

```dart
import 'package:tekartik_build_menu_flutter/app_build_menu.dart';

Future<void> main(List<String> args) async {
  await mainMenu(args, () {
    menuFdmContent();
    item('current device id', () async {
      write('device: ${tkFlutterDeviceIdVar.value}');
    });
  });
}
```

## Common mistakes

* Declaring items outside the `mainMenuConsole`/`mainMenu` callback: nothing
  is registered.
* Expecting the publish menus without passing `androidPublisherClient` to
  `menuAppContent` / `menuFlutterAppContent`.
* Running the android info/publish items before the apk is built
  (`getApkInfo()` throws) or without the Android SDK initialized.
* Adding the package to `dependencies` of the app: it is a `dev_dependencies`
  / globally activated tool.

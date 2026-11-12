# tekartik_build_menu_flutter

An interactive console menu to build, run and publish a Flutter app: create
the platform projects, build and run per flavor, build the aab/apk and copy
them to `deploy/`, check the apk signature, publish to the Play Store, build
the desktop (host) app, run `run_ci`, `pub get`, `flutter clean`...

It drives the `tekartik_build_flutter` builders through the `dev_build` menu.
Dart VM only (a dev tool): every item runs `flutter` (and `adb`, `pod`, the
Android SDK for the android items), which must be on the `PATH`.

## Getting started

Not on pub.dev, add it as a git dev dependency of the app (or of its support
package):

```yaml
dev_dependencies:
  tekartik_build_menu_flutter:
    git:
      url: https://github.com/tekartik/build_flutter.dart
      path: packages/build_menu_flutter
    version: '>=0.4.0'
```

Then a menu script, `tool/build_menu.dart`:

```dart
import 'package:tekartik_build_menu_flutter/app_build_menu.dart';

Future<void> main(List<String> arguments) async {
  mainMenuConsole(arguments, () {
    // The app folder ('.' when the script is in the app), its flavors if any.
    menuAppContent(path: '.', flavors: ['dev', 'prod']);
  });
}
```

`dart run tool/build_menu.dart` shows the menu: type the number of an item (or
of a sub menu), `.` to go back (to exit at the top), `?` to list the items
again. Item numbers given as arguments run first, in order, then the menu
waits for input (`dart run tool/build_menu.dart 2 0 .`: sub menu 2, its item
0, back).

Without touching the app: activate the `fbm` command from a checkout of this
repository (`flutter pub global activate -s path .` in
`packages/build_menu_flutter`), then run `fbm` in the app folder
(`fbm --flavors dev,prod [<app path>]`, `fbm -h` for the usage).

## What is in the menu

- `menuAppContent(path:, flavors:, androidPublisherClient:)`: the whole menu
  from a path (what `fbm` shows), plus a `web` menu.
- `menuFlutterAppContent(builder:)`: the same from a `FlutterAppBuilder` (a
  custom deploy path or module): select flavor, `project` (create the platform
  projects, ios pods, macos entitlements), one `flavor <name>` menu and one
  `host (<platform>, <name>)` menu per flavor (`host (<platform>)` without
  flavor), `build`, `run`, `run_ci`, `pub_get`, `pub_upgrade`, `flutter clean`.
- `menuFlutterAppFlavorContent(flavorBuilder:)`: the menus of one flavor.
- `menuFlutterAppFlavorPublish(flavorBuilder:, client:)`: the Play Store
  items (list bundles and tracks, promote internal to production, publish
  internal); they appear in the menus only when an `androidPublisherClient` is
  given.
- `menuFdmContent()` and `tkFlutterDeviceIdVar`: pick the device the `run on
  device` items use.

## Pitfalls

- Declare the items inside the `mainMenuConsole` callback, nothing is
  registered outside it.
- The android info and publish items read the built apk: build it first.
- It is a dev tool: keep it in `dev_dependencies`.

More (custom items, publish client, device menu): the package skill
`skills/tekartik-build-menu-flutter-menu/SKILL.md`.

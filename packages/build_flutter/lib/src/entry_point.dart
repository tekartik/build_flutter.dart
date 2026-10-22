import 'dart:io';

import 'package:path/path.dart';

import 'build_flutter_common.dart';

/// The entry points a build of [platform] (`android`, `ios`, `web`, `linux`,
/// `macos`, `windows`) of [flavor] looks for, in order, relative to the
/// project: `lib/main_<flavor>.dart`, `lib/main_<platform>.dart`
/// (`lib/main_web.dart`, `lib/main_android.dart`, `lib/main_ios.dart`,
/// `lib/main_linux.dart`...), then `lib/main_host.dart` for a desktop
/// platform.
List<String> flutterProjectEntryPointCandidates({
  String? platform,
  String? flavor,
}) => [
  if (flavor != null) 'lib/main_$flavor.dart',
  if (platform != null) ...[
    'lib/main_$platform.dart',
    if (buildPlatformsDesktopAll.contains(platform)) 'lib/main_host.dart',
  ],
];

/// The entry point of a build of the flutter project at [path] for
/// [platform] and [flavor]: the first of
/// [flutterProjectEntryPointCandidates] that exists, null when none does
/// (`lib/main.dart`, the flutter default).
String? flutterProjectEntryPoint(
  String path, {
  String? platform,
  String? flavor,
}) {
  for (var entryPoint in flutterProjectEntryPointCandidates(
    platform: platform,
    flavor: flavor,
  )) {
    if (File(join(path, entryPoint)).existsSync()) {
      return entryPoint;
    }
  }
  return null;
}

/// The platform a `flutter build <subCommand>` builds for: `android` for
/// `apk`, `appbundle` and `aar`, `ios` for `ipa`, `ios` and `ios-framework`,
/// `macos` for `macos-framework`, the sub command otherwise (`web`, `linux`,
/// `macos`, `windows`).
String flutterBuildSubCommandPlatform(String subCommand) =>
    switch (subCommand) {
      'apk' || 'appbundle' || 'aar' => buildPlatformAndroid,
      'ipa' || 'ios' || 'ios-framework' => buildPlatformIOS,
      'macos-framework' => buildPlatformMacOS,
      _ => subCommand,
    };

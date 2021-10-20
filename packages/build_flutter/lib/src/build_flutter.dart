import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';

import 'build_flutter_common.dart';

/// Current build platform
/// Desktop only
String get buildPlatformCurrent {
  if (Platform.isWindows) {
    return buildPlatformWindows;
  } else if (Platform.isLinux) {
    return buildPlatformLinux;
  } else if (Platform.isMacOS) {
    return buildPlatformMacOS;
  } else {
    throw UnsupportedError('Unsupported platform');
  }
}

Future<void> createProjectAndCheckoutFromGit(String path,
    {String? platform}) async {
  platform ??= buildPlatformCurrent;
  var shell = Shell(workingDirectory: path);
  try {
    // Delete platform directory
    await Directory(join(path, platform)).delete(recursive: true);
  } catch (_) {}
  try {
    // Delete platform directory
    await Directory(path).create(recursive: true);
  } catch (_) {}

  await shell.run('flutter create --platforms $platform .');

  // Try git checkout
  try {
    await shell.run('git checkout $platform');
  } catch (_) {}
}

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

/// Force re-creating a project
Future<void> createProject(String path, {String? platform}) async {
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
}

/// Create project and checkout from git
Future<void> createProjectAndCheckoutFromGit(String path,
    {String? platform}) async {
  platform ??= buildPlatformCurrent;
  await createProject(path, platform: platform);
  await checkoutFromGit(path, platform: platform);
}

/// Create project and checkout from git
Future<void> checkoutFromGit(String path, {String? platform}) async {
  platform ??= buildPlatformCurrent;
  // Try git checkout
  try {
    var shell = Shell(workingDirectory: path);
    await shell.run('git checkout $platform');
  } catch (_) {}
}

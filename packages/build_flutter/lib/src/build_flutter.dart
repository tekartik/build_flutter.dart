import 'dart:io';

import 'package:dev_build/build_support.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:tekartik_build_flutter/src/import.dart';

import 'build_flutter_common.dart';

var _linuxExeDir = join('build', 'linux', 'x64', 'release', 'bundle');
var _windowsExeDir = join('build', 'windows', 'x64', 'runner', 'Release');
var _macOSExeDir = join('build', 'macos', 'Build', 'Products', 'Release');

/// Safe delete a directory
Future<void> deleteDir(String path) async {
  try {
    await Directory(path).delete(recursive: true);
  } catch (_) {}
}

/// Safe delete a file
Future<void> deleteFile(String path) async {
  try {
    await File(path).delete(recursive: true);
  } catch (_) {}
}

/// release exe dir (linux and windows for now)
String get platformExeDir => Platform.isLinux
    ? _linuxExeDir
    : (Platform.isMacOS ? _macOSExeDir : _windowsExeDir);

/// Current build platform
///
/// Desktop only
String get buildPlatformCurrent => _buildHostBuildPlatform[buildHostCurrent]!;

var _buildHostBuildPlatform = {
  buildHostWindows: buildPlatformWindows,
  buildHostLinux: buildPlatformLinux,
  buildHostMacOS: buildPlatformMacOS,
};

var _buildHostSupportedBuildPlatforms = {
  buildHostWindows: [
    buildPlatformWindows,
    buildPlatformAndroid,
    buildPlatformWeb
  ],
  buildHostLinux: [buildPlatformLinux, buildPlatformAndroid, buildPlatformWeb],
  buildHostMacOS: [
    buildPlatformMacOS,
    buildPlatformAndroid,
    buildPlatformIOS,
    buildPlatformWeb
  ],
};

/// Get the supported build platforms for the current host.
List<String>? getBuildHostSupportedPlatforms(
    {
    // Default to buildFlatformCurrent, mainly used for testing
    String? buildHost}) {
  return _buildHostSupportedBuildPlatforms[buildHost ?? buildHostCurrent];
}

final buildHostCurrent = _buildHostCurrent;

/// All supported platform for current host
var buildHostSupportedPlatforms = getBuildHostSupportedPlatforms()!;

/// Current build host, cannot change
String get _buildHostCurrent {
  if (Platform.isWindows) {
    return buildHostWindows;
  } else if (Platform.isLinux) {
    return buildHostLinux;
  } else if (Platform.isMacOS) {
    return buildHostMacOS;
  } else {
    throw UnsupportedError('Unsupported platform');
  }
}

/// Force re-creating a project
Future<void> createProject(String path, {String? platform}) async {
  platform ??= buildPlatformCurrent;
  var shell = Shell(workingDirectory: path);

  // Delete platform directory
  await deleteDir(join(path, platform));
  // Create directory
  await Directory(path).create(recursive: true);

  if (buildPlatformsDesktopAll.contains(platform)) {
    await shell.run('flutter config --enable-$platform-desktop');
  }

  await shell.run('flutter create --platforms $platform .');
}

/// Run the released
Future<void> runBuiltProject(String path) async {
  var appName = await getBuildProjectAppFilename(path);
  var shell = Shell(workingDirectory: join(path, platformExeDir));
  await shell.run(join('.', appName));
}

/// Get the app name
Future<String> getBuildProjectAppFilename(String path) async {
  var appName = (await pathGetPubspecYamlMap(path))['name'] as String;
  if (Platform.isWindows) {
    appName = '$appName.exe';
  } else if (Platform.isMacOS) {
    appName = '$appName.app';
  }
  return appName;
}

/// Recreate and build a project
Future<void> buildProject(String path,
    {String? target, String? platform, String? flavor}) async {
  var shell = Shell(workingDirectory: path);
  platform ??= buildPlatformCurrent;
  var subcommandApk = 'apk';
  var subcommandIpa = 'ipa';
  String? subcommand;
  if (platform == buildPlatformAndroid) {
    subcommand = subcommandApk;
  } else if (platform == buildPlatformIOS) {
    subcommand = subcommandIpa;
  } else {
    // TODO handle other platform such as ios
    subcommand = platform;
  }
  var supportsFlavor = (platform == buildPlatformAndroid) && flavor != null;

  await shell.run('''
    flutter build $subcommand${target != null ? ' --target ${shellArgument(target)}' : ''}${supportsFlavor ? ' --flavor $flavor' : ''}
    ''');
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

@Deprecated('moved')
var getBuildSupportedPlatforms = [
  buildPlatformCurrent,
  buildPlatformWeb,
  if (Platform.isMacOS) buildPlatformIOS,
  buildPlatformAndroid
];

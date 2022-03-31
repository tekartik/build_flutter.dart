import 'dart:io';

import 'package:dev_test/build_support.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';

import 'build_flutter_common.dart';

var _linuxExeDir = join('build', 'linux', 'x64', 'release', 'bundle');
var _windowsExeDir = join('build', 'windows', 'runner', 'Release');
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

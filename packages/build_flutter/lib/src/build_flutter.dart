import 'dart:io';

import 'package:dev_build/build_support.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:tekartik_build_flutter/flutter_project.dart';
import 'package:tekartik_build_flutter/src/import.dart';

import 'build_flutter_common.dart';

var _linuxExeDir = join('build', 'linux', 'x64', 'release', 'bundle');
var _windowsExeDir = join('build', 'windows', 'x64', 'runner', 'Release');
var _macOSExeDir = join('build', 'macos', 'Build', 'Products', 'Release');

/// Safe delete a directory
Future<void> deleteDir(String path) async {
  var dir = Directory(path);
  try {
    if (dir.existsSync()) {
      stdout.writeln('Deleting ${basename(path)}/');
    }

    await Directory(path).delete(recursive: true);
  } catch (_) {}
}

/// Safe delete a file
Future<void> deleteFile(String path) async {
  var file = File(path);
  try {
    if (file.existsSync()) {
      stdout.writeln('Deleting ${basename(path)}');
    }

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
    buildPlatformWeb,
  ],
  buildHostLinux: [buildPlatformLinux, buildPlatformAndroid, buildPlatformWeb],
  buildHostMacOS: [
    buildPlatformMacOS,
    buildPlatformAndroid,
    buildPlatformIOS,
    buildPlatformWeb,
  ],
};

/// Get the supported build platforms for the current host.
List<String>? getBuildHostSupportedPlatforms({
  // Default to buildFlatformCurrent, mainly used for testing
  String? buildHost,
}) {
  return _buildHostSupportedBuildPlatforms[buildHost ?? buildHostCurrent];
}

/// Current build host
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

/// True if the platform project folder (`linux`, `android`...) exists.
///
/// [platform] defaults to the current host platform.
bool hasPlatformProject(String path, {String? platform}) {
  platform ??= buildPlatformCurrent;
  return Directory(join(path, platform)).existsSync();
}

/// Force re-creating a project
Future<void> createProject(
  String path, {
  String? platform,
  String? template,
}) async {
  await FlutterProject(
    path,
    buildPlatform: platform,
  ).createProject(template: template);
}

/// Find the macOS app bundle (`my_app.app`) in [dirPath], null if none.
///
/// [appName] (`my_app.app`) is looked for first, otherwise the first bundle
/// found is used (the product name can differ from the pubspec name).
String? _macOSFindAppBundlePath(String dirPath, {String? appName}) {
  if (appName != null) {
    var bundlePath = join(dirPath, appName);
    if (Directory(bundlePath).existsSync()) {
      return bundlePath;
    }
  }
  var dir = Directory(dirPath);
  if (dir.existsSync()) {
    for (var entity in dir.listSync()) {
      if (entity is Directory && extension(entity.path) == '.app') {
        return entity.path;
      }
    }
  }
  return null;
}

/// Find the executable in a macOS app bundle
/// (`my_app.app/Contents/MacOS/my_app`), null if none.
String? _macOSFindAppBundleExePath(String bundlePath) {
  var macOSDirPath = join(bundlePath, 'Contents', 'MacOS');
  // Default is the product name (i.e. the bundle name without its extension)
  var exePath = join(macOSDirPath, basenameWithoutExtension(bundlePath));
  if (File(exePath).existsSync()) {
    return exePath;
  }
  var macOSDir = Directory(macOSDirPath);
  if (macOSDir.existsSync()) {
    for (var entity in macOSDir.listSync()) {
      if (entity is File) {
        return entity.path;
      }
    }
  }
  return null;
}

/// Get the built app path (relative to the current directory if [path] is
/// relative).
///
/// On macOS this is the `my_app.app` bundle (i.e. a directory), on other
/// platforms this is the executable itself.
///
/// Throws if the project was not built.
Future<String> getBuildProjectAppPath(String path) async {
  var exeDirPath = join(path, platformExeDir);
  var appName = await getBuildProjectAppFilename(path);
  if (Platform.isMacOS) {
    var bundlePath = _macOSFindAppBundlePath(exeDirPath, appName: appName);
    if (bundlePath == null) {
      throw StateError(
        'No app bundle (.app) found in $exeDirPath, build the project first',
      );
    }
    return bundlePath;
  }
  return join(exeDirPath, appName);
}

/// Get the built executable path (relative to the current directory if [path]
/// is relative).
///
/// On macOS, `my_app.app` is a bundle (i.e. a directory) that cannot be run
/// as is, the executable it contains
/// (`my_app.app/Contents/MacOS/my_app`) is returned.
///
/// Throws if the project was not built.
Future<String> getBuildProjectExePath(String path) async {
  var appPath = await getBuildProjectAppPath(path);
  if (Platform.isMacOS) {
    var exePath = _macOSFindAppBundleExePath(appPath);
    if (exePath == null) {
      throw StateError('No executable found in $appPath');
    }
    return exePath;
  }
  return appPath;
}

/// Run the released
///
/// On macOS the app bundle is launched using `open -na`, like a double click
/// in the Finder (proper activation, new instance, the call returns as soon
/// as the app is launched).
///
/// Set [console] to true to run the executable in the bundle directly
/// instead: stdout/stderr are then visible and the call waits for the app to
/// exit (needed in tests). It has no effect on other platforms where the
/// executable is always run directly.
Future<void> runBuiltProject(String path, {bool? console}) async {
  var exeDirPath = join(path, platformExeDir);
  var shell = Shell(workingDirectory: exeDirPath);
  if (Platform.isMacOS && !(console ?? false)) {
    var bundlePath = normalize(absolute(await getBuildProjectAppPath(path)));
    await shell.run('open -na ${shellArgument(bundlePath)}');
  } else {
    var exePath = await getBuildProjectExePath(path);
    await shell.run(
      shellArgument(join('.', relative(exePath, from: exeDirPath))),
    );
  }
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
Future<void> buildProject(
  String path, {
  String? target,
  String? platform,
  String? flavor,
}) async {
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
Future<void> createProjectAndCheckoutFromGit(
  String path, {
  String? platform,
  String? template,
}) async {
  platform ??= buildPlatformCurrent;

  await createProject(path, platform: platform, template: template);

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
/// Get the supported platforms
var getBuildSupportedPlatforms = [
  buildPlatformCurrent,
  buildPlatformWeb,
  if (Platform.isMacOS) buildPlatformIOS,
  if (Platform.isMacOS) buildPlatformMacOS,
  buildPlatformAndroid,
  if (Platform.isLinux) buildPlatformLinux,
  if (Platform.isWindows) buildPlatformWindows,
];

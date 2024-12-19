import 'package:fs_shim/utils/path.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:tekartik_android_utils/build_utils.dart';
import 'package:tekartik_build_flutter/build_flutter.dart';
import 'package:tekartik_common_utils/list_utils.dart';

import 'import.dart';

/// Default to 'app'
const defaultAppAndroidModule = 'app';

/// build type release
const buildTypeRelease = 'release';

/// build type debug
const buildTypeDebug = 'debug';

/// Flutter project
class FlutterProject {
  /// The path
  late final String path;

  /// Default to 'app'
  late final String androidModule;

  /// build platform
  late final String buildPlatform;

  /// Defatul to release
  late final String buildType;

  /// Optional flavors
  late List<String> flavors;

  /// True if has flavors
  bool get hasFlavors => flavors.isNotEmpty;

  /// windows/posix path ok
  FlutterProject(String path,
      {
      /// Default to empty
      List<String>? flavors,
      String? buildPlatform,
      String? androidModule,
      String? buildType}) {
    this.flavors = flavors ?? [];
    this.buildPlatform = buildPlatformCurrent;
    this.androidModule = androidModule ?? defaultAppAndroidModule;
    this.buildType = buildTypeRelease;
    this.path = toNativePath(path);
  }

  // build/app/outputs/bundle/mainRelease/app-main-release.aab
  // build/app/outputs/flutter-apk/app-main-release.apk
  /// Single flavor, if any
  String? get flavor => listSingleOrNull(flavors);

  /// Get the absolute path
  String getAbsolutePath() => normalize(absolute((path)));

  /// Get the absolute apk path
  String getAbsoluteApkPath() => join(getAbsolutePath(), getApkPath());

  /// Get the absolute aab path
  String getAbsoluteAppBundlePath() =>
      join(getAbsolutePath(), getAppBundlePath());

  @Deprecated('use getAbsoluteAppBundlePath')

  /// Get the absolute aab path
  String getAbsoluteAabPath() => join(getAbsolutePath(), getAppBundlePath());

  /// shell
  late final shell = Shell(workingDirectory: path);

  /// Single flavor supported
  Future<void> buildAndroidApk({String? target}) async {
    var subcommand = 'apk';
    await _buildAndroid(subcommand: subcommand, target: target);
  }

  /// Single flavor supported
  Future<void> buildAppBundle({String? target}) async {
    var subcommand = 'appbundle';
    await _buildAndroid(subcommand: subcommand, target: target);
  }

  /// Single flavor supported
  Future<void> _buildAndroid(
      {required String subcommand, String? target}) async {
    /// Recreate and build a project
    await shell.run('''
    flutter build $subcommand${target != null ? ' --target ${shellArgument(target)}' : ''}${hasFlavors ? ' --flavor $flavor' : ''}
    ''');
  }

  /// build/app/outputs
  late final moduleBuildDirOutput = join('build', androidModule, 'outputs');

  /// Path relative to the project directory
  String getApkPath() {
    // 'build/app/outputs/flutter-apk/app-release.apk';
    // build/app/outputs/flutter-apk/app-main-release.apk

    /// Has flavors
    // if (flavors.isNotEmpty) {
    var parts = [androidModule, ...flavors, buildType];

    return join(
        moduleBuildDirOutput, 'flutter-apk', '${_minusWords(parts)}.apk');
    //} else {
    //  return join(moduleBuildDirOutput, 'flutter-apk', app-release.apk';'
    //}
  }

  /// Path relative to the project directory
  String getAppBundlePath() {
    // build/app/outputs/bundle/release/app-release.aab
    // 'build/app/outputs/bundle/customRelease/app-custom-release.aab';

    /// Has flavors
    // if (flavors.isNotEmpty) {
    var folderParts = [...flavors, buildType];
    var parts = [androidModule, ...folderParts];

    // build/app/outputs/bundle/release/app-release.aab
    // 'build/app/outputs/bundle/customRelease/app-custom-release.aab';
    return join(moduleBuildDirOutput, 'bundle',
        _lowerCamelCaseWords(folderParts), '${_minusWords(parts)}.aab');
    //} else {
    //  return join(moduleBuildDirOutput, 'flutter-apk', app-release.apk';'
    //}
  }

// 'build/app/outputs/bundle/customRelease/app-custom-release.aab';
// _lowerCamelCaseWords(parts),

  /// Get the absolute path
  String getAbsolutePathFromRelative(String relative) {
    return join(getAbsolutePath(), relative);
  }
}

String _camelCaseWord(String word) {
  // Handle 1 or 0 characters
  if (word.length < 2) {
    return word.toUpperCase();
  }
  return '${word.substring(0, 1).toUpperCase()}${word.substring(1)}';
}

String _camelCaseWords(List<String> words) =>
    words.map((e) => _camelCaseWord(e)).join();

String _minusWords(List<String> words) => words.join('-');

// Start with lower case
// Must be non empty
String _lowerCamelCaseWords(List<String> words) {
  assert(words.isNotEmpty);
  if (words.length > 1) {
    return '${words.first}${_camelCaseWords(words.sublist(1))}';
  }
  return words.first;
}

/// Get the flutter project
Future<bool> initFlutterAndroidBuild({int? sdkVersion}) async {
  var context = await getAndroidBuildContext(sdkVersion: sdkVersion);
  if (context.androidSdkBuildToolsPath != null) {
    try {
      await initAndroidBuildEnvironment(context: context);
      return true;
    } catch (_) {}
  }
  return false;
}

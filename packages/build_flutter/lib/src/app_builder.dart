import 'dart:io';

import 'package:fs_shim/utils/io/copy.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:tekartik_android_utils/apk_utils.dart' as apk_utils;
import 'package:tekartik_build_flutter/flutter_devices.dart';
import 'package:tekartik_built_flutter/constant.dart';
import 'package:tekartik_common_build/common_app_builder.dart';
import 'package:tekartik_playstore_publish/playstore_publish.dart';

/// Clean a web app
Future<void> flutterProjectClean(String directory) async {
  var shell = Shell().cd(directory);
  await shell.run('flutter clean');
}

/// Flutter app build options
class FlutterAppBuildOptions {
  /// flavors
  final List<String>? flavors;

  /// Constructor
  FlutterAppBuildOptions({this.flavors});
}

/// Web app options
class FlutterAppContext {
  /// Path
  final String path;

  /// default to 'app'
  late final String module;

  /// Build options
  final FlutterAppBuildOptions? buildOptions;

  /// Constructor
  FlutterAppContext({this.path = '.', this.buildOptions, String? module}) {
    this.module = module ?? 'app';
  }

  /// Copy with
  FlutterAppContext copyWith({
    String? path,
    FlutterAppBuildOptions? buildOptions,
  }) {
    return FlutterAppContext(
      path: path ?? this.path,
      buildOptions: buildOptions ?? this.buildOptions,
    );
  }
}

/// Flutter app flavor builder
class FlutterAppFlavorBuilder {
  /// App builder
  final FlutterAppBuilder appBuilder;

  /// Flavor
  final String? flavor;

  /// Path
  String get path => appBuilder.path;

  /// Module
  String get module => appBuilder.module;

  /// Constructor
  FlutterAppFlavorBuilder({required this.appBuilder, required this.flavor});

  /// For display
  String get flavorName => flavor ?? 'main';

  /// Apks deploy path (folder)
  @Deprecated('use apks')
  String get apkDeployPath => apksDeployPath;

  /// Apks deploy path (folder)
  String get apksDeployPath => appBuilder.apksDeployPath;

  /// Aabs deploy path (folder
  @Deprecated('use aabsDeployPath')
  String get aabDeployPath => aabsDeployPath;

  /// Aabs deploy path (folder
  String get aabsDeployPath => appBuilder.aabsDeployPath;

  /// Get flutter target option
  String getFlutterTargetOption({String? flavor}) {
    var sb = StringBuffer();
    if (flavor != null) {
      sb.write(
        ' --flavor $flavor  --dart-define=$envFlavorKey="$flavor" --target lib/main_$flavor.dart',
      );
    }
    return sb.toString();
  }

  /// Build
  Future<void> build(String buildSubCommand) async {
    var shell = Shell().cd(path);
    var sb = StringBuffer(buildSubCommand);
    if (flavor != null) {
      sb.write(getFlutterTargetOption(flavor: flavor));
    }
    //sb.write(' $');
    await shell.run('flutter build $sb');
  }

  /// Clean
  Future<void> clean() async {
    await flutterProjectClean(path);
  }

  /// Flavor to path
  static String flavorToPath(String flavor) {
    var sb = StringBuffer();
    var parts = flavor.split('-');
    sb.write(parts[0]);
    for (var i = 1; i < parts.length; i++) {
      var part = parts[i];
      sb.write(part.substring(0, 1).toUpperCase());
      sb.write(part.substring(1));
    }
    return sb.toString();
  }

  /// Get apk path
  String getApkPath() {
    return _getAndroidBuiltObjectPath(
      flavor: flavor,
      module: module,
      extension: 'apk',
      folder: 'apk',
    );
  }

  /// Get aab path
  String getAabPath({String? module}) {
    return _getAndroidBuiltObjectPath(
      flavor: flavor,
      module: module,
      extension: 'aab',
      folder: 'bundle',
      useFlavorToPath: true,
    );
  }

  /// object: apk, aab
  /// folder: apk, bundle
  String _getAndroidBuiltObjectPath({
    String? flavor,
    String? module,

    /// Needed for aab convert dev-release to devRelease
    bool? useFlavorToPath,
    required String extension,
    required String folder,
  }) {
    module ??= 'app';
    var buildTop = join(path, 'build', module, 'outputs', folder);
    if (flavor != null) {
      var flavorPath = flavorToPath(flavor);
      var objectName = '$module-$flavor-release.$extension';
      String objectFile;
      if (useFlavorToPath ?? false) {
        objectFile = join(
          buildTop,
          flavorToPath('$flavor-release'),
          objectName,
        );
      } else {
        objectFile = join(buildTop, flavorPath, 'release', objectName);
      }
      return objectFile;
    } else {
      return join(buildTop, 'release', 'app-release.$extension');
    }
  }

  /// Build apk
  Future<void> buildAndroidApk() async {
    await build('apk');
  }

  /// Build aab
  Future<void> buildAndroidAab() async {
    await build('appbundle');
  }

  /// Build ios ipa
  Future<void> buildIosIpa() async {
    await build('ipa');
  }

  /// Either publisher or api must be provided
  Future<void> androidBuildAndPublish({
    required AndroidPublisherClient client,
  }) async {
    var apkInfo = await buildAndroidAndCopy();
    await androidPublish(client: client, apkInfo: apkInfo);
  }

  /// Assume androd build and copy has been called
  Future<void> androidPublish({
    required AndroidPublisherClient client,
    apk_utils.ApkInfo? apkInfo,
  }) async {
    apkInfo ??= await getApkInfo();
    var versionCode = int.parse(apkInfo.versionCode!);
    var publisher = AndroidPublisher(
      packageName: apkInfo.name!,
      client: client,
    );

    var aabPath = getAabPath();
    await publisher.uploadBundleAndPublish(
      aabPath: aabPath,
      trackName: publishTrackInternal,
      versionCode: versionCode,
      //    changesNotSentForReview: true
    );

    stdout.writeln('publishing done $apkInfo');
  }

  /// Build and copy
  Future<apk_utils.ApkInfo> buildAndroidAndCopy() async {
    await buildAndroidApk();
    await buildAndroidAab();
    var apkInfo = await getApkInfo();
    await copyApk(apkInfo: apkInfo);
    await copyAab(apkInfo: apkInfo);
    return apkInfo;
  }

  /// Need aab and apk
  Future<void> copyAndroid({String? flavor}) async {
    var apkInfo = await getApkInfo();
    await copyApk(apkInfo: apkInfo);
    await copyAab(apkInfo: apkInfo);
  }

  /// Get sha1
  Future<String?> keytoolGetSha1({String? flavor}) async {
    var apkPath = getApkPath();
    try {
      return await apk_utils.apkExtractSha1Digest(apkPath);
    } catch (e) {
      stderr.writeln('keytool error: $e');
    }
    return null;
  }

  /// Must succeed.
  Future<apk_utils.ApkInfo> getApkInfo() async {
    var apkPath = getApkPath();
    var apkInfo = await apk_utils.getApkInfo(apkPath);
    if (apkInfo != null) {
      return apkInfo;
    }
    throw 'no apk info at $apkPath';
  }

  /// Get sha1
  Future<String?> apkSignerGetSha1() async {
    var apkPath = getApkPath();
    try {
      return await apk_utils.getApkSha1(apkPath);
    } catch (e) {
      stderr.writeln('apksigner error: $e');
    }
    return null;
  }

  /// Get deploy base name
  String getDeployBaseName({required apk_utils.ApkInfo apkInfo}) {
    var fullVersionName = '${apkInfo.versionName}';
    // devPrint(fullVersionName);
    // var nameHasVersionCodeSuffix = fullVersionName.split('-').length > 1;
    var versionName = fullVersionName.split('-')[0];
    var basename =
        '${apkInfo.name}_${versionName}_${apkInfo.versionCode}${flavor != null ? '-$flavor' : ''}';

    return basename;
  }

  Future<void> _copyFile(String src, String dst) async {
    if (!isAbsolute(src)) {
      src = join(path, src);
    }
    if (!isAbsolute(dst)) {
      dst = join(path, dst);
    }
    await Directory(dirname(dst)).create(recursive: true);
    var dstFile = File(dst);
    await copyFile(File(src), dstFile);
    stdout.writeln('copy $src to $dst');
    stdout.writeln('  ${basename(dstFile.path)} ${dstFile.statSync().size}');
  }

  /// Get apk path
  Future<String> getApkDeployedPath({apk_utils.ApkInfo? apkInfo}) async {
    apkInfo ??= await getApkInfo();
    var basename = getDeployBaseName(apkInfo: apkInfo);
    var dstFileName = '$basename.apk';
    var dst = join(apksDeployPath, dstFileName);
    return dst;
  }

  /// Copy apk
  Future<void> copyApk({apk_utils.ApkInfo? apkInfo}) async {
    var apkPath = getApkPath();
    var dst = await getApkDeployedPath(apkInfo: apkInfo);
    await _copyFile(apkPath, dst);
  }

  /// Copy aab
  Future copyAab({required apk_utils.ApkInfo apkInfo}) async {
    var aabPath = getAabPath();
    var basename = getDeployBaseName(apkInfo: apkInfo);
    var dstFileName = '$basename.aab';
    var dst = join(aabsDeployPath, dstFileName);
    await _copyFile(aabPath, dst);
  }

  /// Run the build apk
  Future<void> runBuiltAndroidApk({
    apk_utils.ApkInfo? apkInfo,
    required String activity,
  }) async {
    apkInfo ??= await getApkInfo();

    var ipDevice =
        (await getFlutterDevices()).android.supported.firstOrNull?.id.v;
    if (ipDevice != null) {
      var startParam = '${apkInfo.name}/$activity';
      var shell = Shell(workingDirectory: path);
      await shell.run(
        'adb -s ${shellArgument(ipDevice)} shell am start -n ${shellArgument(startParam)}',
      );
    } else {
      stderr.writeln('No android device found');
    }
  }

  /// Install the deployed apk
  Future<void> installDeployedApk({apk_utils.ApkInfo? apkInfo}) async {
    var apkPath = await getApkDeployedPath(apkInfo: apkInfo);
    var ipDevice =
        (await getFlutterDevices()).android.supported.firstOrNull?.id.v;
    if (ipDevice != null) {
      var shell = Shell(workingDirectory: path);
      await shell.run(
        'adb -s ${shellArgument(ipDevice)} install ${shellArgument(apkPath)}',
      );
    } else {
      stderr.writeln('No android device found');
    }
  }
}

/// Convenient builder.
class FlutterAppBuilder implements CommonAppBuilder {
  /// Context
  final FlutterAppContext context;

  /// Deploy path
  late final String deployPath;

  /// Path
  @override
  String get path => context.path;

  /// Module
  String get module => context.module;

  /// Constructor
  FlutterAppBuilder({String? deployPath, required this.context}) {
    this.deployPath = deployPath ?? 'deploy';
  }

  /// Flavors
  List<String> get flavors => context.buildOptions?.flavors ?? <String>[];

  /// Flavor builders
  List<FlutterAppFlavorBuilder> get flavorBuilders {
    if (flavors.isNotEmpty) {
      return flavors.map((flavor) {
        return FlutterAppFlavorBuilder(appBuilder: this, flavor: flavor);
      }).toList();
    } else {
      return [defaultFlavorBuilder];
    }
  }

  /// Default flavor builder
  FlutterAppFlavorBuilder get defaultFlavorBuilder =>
      FlutterAppFlavorBuilder(appBuilder: this, flavor: null);

  @Deprecated('Use defaultFlavorBuilder')
  /// Default flavor builder
  FlutterAppFlavorBuilder get defaultFlavorBuild => defaultFlavorBuilder;

  /// apks deploy path
  @Deprecated('use apksDeployPath')
  String get apkDeployPath => apksDeployPath;

  /// apks deploy path
  String get apksDeployPath => join(deployPath, 'apk');

  /// aabs deploy path
  @Deprecated('use aabsDeployPath')
  String get aabDeployPath => aabsDeployPath;

  /// aab deploy path
  String get aabsDeployPath => join(deployPath, 'aab');
}

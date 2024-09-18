import 'dart:io';

import 'package:fs_shim/utils/io/copy.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:tekartik_android_utils/apk_utils.dart' as apk_utils;
import 'package:tekartik_built_flutter/constant.dart';
import 'package:tekartik_playstore_publish/playstore_publish.dart';

/// Clean a web app
Future<void> flutterProjectClean(String directory) async {
  var shell = Shell().cd(directory);
  await shell.run('flutter clean');
}

class FlutterAppBuildOptions {
  final List<String>? flavors;
  FlutterAppBuildOptions({this.flavors});
}

/// Web app options
class FlutterAppContext {
  final String path;

  /// default to 'app'
  late final String module;
  final FlutterAppBuildOptions? buildOptions;

  FlutterAppContext({this.path = '.', this.buildOptions, String? module}) {
    this.module = module ?? 'app';
  }

  FlutterAppContext copyWith(
      {String? path, FlutterAppBuildOptions? buildOptions}) {
    return FlutterAppContext(
      path: path ?? this.path,
      buildOptions: buildOptions ?? this.buildOptions,
    );
  }
}

class FlutterAppFlavorBuilder {
  final FlutterAppBuilder appBuilder;
  final String? flavor;

  String get path => appBuilder.path;
  String get module => appBuilder.module;
  FlutterAppFlavorBuilder({required this.appBuilder, required this.flavor});

  /// For display
  String get flavorName => flavor ?? 'main';

  String get apkDeployPath => appBuilder.apkDeployPath;
  String get aabDeployPath => appBuilder.aabDeployPath;

  String getFlutterTargetOption({String? flavor}) {
    var sb = StringBuffer();
    if (flavor != null) {
      sb.write(
          ' --flavor $flavor  --dart-define=$envFlavorKey="$flavor" --target lib/main_$flavor.dart');
    }
    return sb.toString();
  }

  Future<void> build(String buildSubCommand) async {
    var shell = Shell().cd(path);
    var sb = StringBuffer(buildSubCommand);
    if (flavor != null) {
      sb.write(getFlutterTargetOption(flavor: flavor));
    }
    //sb.write(' $');
    await shell.run('flutter build $sb');
  }

  Future<void> clean() async {
    await flutterProjectClean(path);
  }

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

  String getApkPath() {
    return _getAndroidBuiltObjectPath(
        flavor: flavor, module: module, extension: 'apk', folder: 'apk');
  }

  String getAabPath({String? module}) {
    return _getAndroidBuiltObjectPath(
        flavor: flavor,
        module: module,
        extension: 'aab',
        folder: 'bundle',
        useFlavorToPath: true);
  }

  /// object: apk, aab
  /// folder: apk, bundle
  String _getAndroidBuiltObjectPath(
      {String? flavor,
      String? module,

      /// Needed for aab convert dev-release to devRelease
      bool? useFlavorToPath,
      required String extension,
      required String folder}) {
    module ??= 'app';
    var buildTop = join(path, 'build', module, 'outputs', folder);
    if (flavor != null) {
      var flavorPath = flavorToPath(flavor);
      var objectName = '$module-$flavor-release.$extension';
      String objectFile;
      if (useFlavorToPath ?? false) {
        objectFile =
            join(buildTop, flavorToPath('$flavor-release'), objectName);
      } else {
        objectFile = join(buildTop, flavorPath, 'release', objectName);
      }
      return objectFile;
    } else {
      return join(buildTop, 'release', 'app-release.$extension');
    }
  }

  Future<void> buildAndroidApk() async {
    await build('apk');
  }

  Future<void> buildAndroidAab() async {
    await build('appbundle');
  }

  Future<void> buildIosIpa() async {
    await build('ipa');
  }

  /// Either publisher or api must be provided
  Future<void> androidBuildAndPublish(
      {required AndroidPublisherClient client}) async {
    var apkInfo = await buildAndroidAndCopy();
    await androidPublish(client: client, apkInfo: apkInfo);
  }

  /// Assume androd build and copy has been called
  Future<void> androidPublish(
      {required AndroidPublisherClient client,
      apk_utils.ApkInfo? apkInfo}) async {
    apkInfo ??= await getApkInfo();
    var versionCode = int.parse(apkInfo.versionCode!);
    var publisher =
        AndroidPublisher(packageName: apkInfo.name!, client: client);

    var aabPath = getAabPath();
    await publisher.uploadBundleAndPublish(
      aabPath: aabPath,
      trackName: publishTrackInternal,
      versionCode: versionCode,
      //    changesNotSentForReview: true
    );

    print('publishing done $apkInfo');
  }

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

  Future<String?> keytoolGetSha1({String? flavor}) async {
    var apkPath = getApkPath();
    try {
      return await apk_utils.apkExtractSha1Digest(apkPath);
    } catch (e) {
      print('keytool error: $e');
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

  Future<String?> apkSignerGetSha1() async {
    var apkPath = getApkPath();
    try {
      return await apk_utils.getApkSha1(apkPath);
    } catch (e) {
      print('apksigner error: $e');
    }
    return null;
  }

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
    print('copy $src to $dst');
    stdout.writeln('  ${basename(dstFile.path)} ${dstFile.statSync().size}');
  }

  Future copyApk({required apk_utils.ApkInfo apkInfo}) async {
    var apkPath = getApkPath();
    var basename = getDeployBaseName(apkInfo: apkInfo);
    var dstFileName = '$basename.apk';
    var dst = join(apkDeployPath, dstFileName);
    await _copyFile(apkPath, dst);
  }

  Future copyAab({required apk_utils.ApkInfo apkInfo}) async {
    var aabPath = getAabPath();
    var basename = getDeployBaseName(apkInfo: apkInfo);
    var dstFileName = '$basename.aab';
    var dst = join(aabDeployPath, dstFileName);
    await _copyFile(aabPath, dst);
  }
}

/// Convenient builder.
class FlutterAppBuilder {
  final FlutterAppContext context;

  late final String deployPath;

  String get path => context.path;
  String get module => context.module;
  FlutterAppBuilder({String? deployPath, required this.context}) {
    this.deployPath = deployPath ?? 'deploy';
  }
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

  FlutterAppFlavorBuilder get defaultFlavorBuilder =>
      FlutterAppFlavorBuilder(appBuilder: this, flavor: null);

  @Deprecated('Use defaultFlavorBuilder')
  FlutterAppFlavorBuilder get defaultFlavorBuild => defaultFlavorBuilder;
  String get apkDeployPath => join(deployPath, 'apk');
  String get aabDeployPath => join(deployPath, 'aab');
}

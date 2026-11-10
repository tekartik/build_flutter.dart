// ignore_for_file: avoid_print

import 'package:tekartik_build_flutter/app_builder.dart';
import 'package:tekartik_build_flutter/build_flutter.dart';

/// The release builds of a flutter app with two flavors, from its `tool/`
/// script: `dart run tool/build.dart android|host`.
///
/// Without argument, prints what would be built and where, building nothing.
Future<void> main(List<String> args) async {
  var builder = FlutterAppBuilder(
    context: FlutterAppContext(
      path: '.',
      buildOptions: FlutterAppBuildOptions(flavors: ['dev', 'prod']),
    ),
  );
  switch (args.firstOrNull) {
    case 'android':
      for (var flavorBuilder in builder.flavorBuilders) {
        var apkInfo = await flavorBuilder.buildAndroidAndCopy();
        print(await flavorBuilder.getApkDeployedPath(apkInfo: apkInfo));
      }
    case 'host':
      // Creates the desktop platform folder when missing, builds the
      // release and copies it to deploy/<platform>-prod.
      var prod = builder.flavorBuilder('prod');
      await prod.buildHost();
      print(prod.hostDeployPath);
    default:
      print('host platform: $buildPlatformCurrent');
      print('buildable here: ${getBuildHostSupportedPlatforms()}');
      for (var flavorBuilder in builder.flavorBuilders) {
        print('${flavorBuilder.flavorName}:');
        print('  apk: ${flavorBuilder.getApkPath()}');
        print('  aab: ${flavorBuilder.getAabPath()}');
        print('  host deploy: ${flavorBuilder.hostDeployPath}');
      }
  }
}

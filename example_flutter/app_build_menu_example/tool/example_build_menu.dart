import 'dart:io';

import 'package:process_run/shell.dart';

import 'package:tekartik_build_menu_flutter/app_build_menu.dart';

Future main(List<String> arguments) async {
  await initAndroidBuildEnvironment();
  var appPath = '.';
  mainMenuConsole(arguments, () {
    if (Platform.isWindows || Platform.isLinux) {
      item('build and run marker', () async {
        await createProject('.');
        await buildProject('.', target: 'lib/create_file_and_exit_main.dart');
        await runBuiltProject('.');
      });
      item('build and run example (host)', () async {
        await createProject('.');
        await buildProject('.');
        await runBuiltProject('.');
      });
      item('Run android', () async {
        var device = (await getFlutterDevices()).supported.android.firstOrNull;
        if (device == null) {
          write('No android device found');
          return;
        }
        await createProject('.', platform: buildPlatformAndroid);
        var shell = Shell(workingDirectory: appPath);
        await shell.run('flutter run -d ${device.id.v}');
      });
      var context = FlutterAppContext(path: appPath);
      var builder = FlutterAppBuilder(context: context);
      var flavorBuilder = builder.defaultFlavorBuilder;
      item('Build apk', () async {
        var device = (await getFlutterDevices()).supported.android.firstOrNull;
        if (device == null) {
          write('No android device found');
          return;
        }
        await createProject('.', platform: buildPlatformAndroid);
        var apkInfo = await flavorBuilder.buildAndroidAndCopy();
        write(apkInfo);
      });
      item('Run built apk', () async {
        var apkInfo = await flavorBuilder.getApkInfo();
        await flavorBuilder.installDeployedApk(apkInfo: apkInfo);
        await flavorBuilder.runBuiltAndroidApk(
            activity: 'com.example.app_build_menu_example.MainActivity');
      });
    }
    menuAppContent(path: appPath);
  });
}

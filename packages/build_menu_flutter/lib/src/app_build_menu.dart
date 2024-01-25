import 'package:dev_test/build_support.dart';
import 'package:dev_test/package.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart' hide prompt;
// ignore: depend_on_referenced_packages
import 'package:tekartik_android_utils/build_utils.dart';
import 'package:tekartik_build_flutter/app_builder.dart';
import 'package:tekartik_build_flutter/build_flutter.dart';
import 'package:tekartik_common_utils/list_utils.dart'; // ignore: depend_on_referenced_packages
import 'package:tekartik_test_menu_io/test_menu_io.dart';

var androidReady = initAndroidBuildEnvironment();

Future main(List<String> arguments) async {
  mainMenu(arguments, menuAppContent);
}

/// To deprecate
void menuAppContent({String path = '.', List<String>? flavors}) {
  var builder = FlutterAppBuilder(
      context: FlutterAppContext(
          path: path, buildOptions: FlutterAppBuildOptions(flavors: flavors)));
  menuFlutterAppContent(builder: builder);
}

void menuFlutterAppFlavorContent(
    {required FlutterAppFlavorBuilder flavorBuilder}) {
  Future<void> printApkSha1() async {
    try {
      write('apksigner: ${await flavorBuilder.apkSignerGetSha1()}');
    } catch (_) {}
    try {
      write('keytool: ${await flavorBuilder.keytoolGetSha1()}');
    } catch (_) {}
  }

  menu('flavor ${flavorBuilder.flavorName}', () {
    item('clean', () async {
      await flavorBuilder.clean();
    });
    menu('ios', () {
      item('build ipa', () async {
        await flavorBuilder.buildIosIpa();
      });
      item('clean, build ipa', () async {
        await flavorBuilder.clean();
        await flavorBuilder.buildIosIpa();
      });
    });
    menu('android', () {
      item('build aab', () async {
        await androidReady;
        await flavorBuilder.buildAndroidAab();
      });
      item('build apk', () async {
        await androidReady;
        await flavorBuilder.buildAndroidApk();
      });
      item('sha1', () async {
        await androidReady;
        await printApkSha1();
      });
      item('apkinfo', () async {
        await androidReady;

        write('apkinfo: ${await flavorBuilder.getApkInfo()}');
        write(
            'apkinfo: ${jsonEncode((await flavorBuilder.getApkInfo()).toMap())}');
      });
      item('build aab & apk and copy', () async {
        await androidReady;
        await flavorBuilder.buildAndroidAndCopy();
      });
      item('clean, build aab & apk and copy', () async {
        await androidReady;
        await flavorBuilder.clean();
        await flavorBuilder.buildAndroidAndCopy();
      });

      item('copy aab & apk', () async {
        await androidReady;
        await flavorBuilder.copyAndroid();
        await printApkSha1();
      });
    });
  });
}

void menuFlutterAppContent({required FlutterAppBuilder builder}) {
  var appPath = builder.path;
  var flavors = builder.flavors;
  var appShell = Shell(workingDirectory: appPath);
  var currentFlavor = listFirst(flavors);

  Map pubspec;
  var checkPubspec = () async {
    try {
      pubspec = await pathGetPubspecYamlMap(appPath);
      return pubspec;
    } catch (_) {}
    return <String, Object?>{};
  }();

  Future<bool> checkFlutterSupported() async {
    var pubspec = await checkPubspec;
    // devWrite(jsonPretty(pubspec));
    var supported = pubspecYamlSupportsFlutter(pubspec);
    if (!supported) {
      write('flutter not supported');
      var response = await prompt('Continue Y/N');
      if (response?.toLowerCase() == 'y') {
        return true;
      }
    }
    return supported;
  }

  enter(() async {
    write('App path: ${absolute(appPath)}');
    var pubspec = await checkPubspec;
    write('Package: ${pubspec['name']}');
  });
  if (currentFlavor != null) {
    menu('select flavor', () {
      void dump() {
        write('current flavor: $currentFlavor');
      }

      enter(() async {
        dump();
      });
      for (var flavor in flavors) {
        item(flavor, () {
          dump();
          currentFlavor = flavor;
          dump();
        });
      }
    });
  }
  menu('project', () {
    item('create current platform project ($buildPlatformCurrent)', () async {
      if (await checkFlutterSupported()) {
        await createProject(appPath);
      }
    });
    for (var platform in buildHostSupportedPlatforms) {
      item('create platform project ($platform)', () async {
        if (await checkFlutterSupported()) {
          await createProject(appPath, platform: platform);
        }
      });
    }
  });
  if (builder.context.buildOptions?.flavors?.isNotEmpty ?? false) {
    menu('flavors', () {
      for (var flavorBuilder in builder.flavorBuilders) {
        menuFlutterAppFlavorContent(flavorBuilder: flavorBuilder);
      }
    });
  } else {
    menuFlutterAppFlavorContent(flavorBuilder: builder.flavorBuilders.first);
  }
  menu('build', () {
    for (var platform in buildHostSupportedPlatforms) {
      item('build $platform', () async {
        if (await checkFlutterSupported()) {
          await buildProject(appPath,
              platform: platform, flavor: currentFlavor);
        }
      });
    }
  });
  menu('run', () {
    item('run desktop built', () async {
      await runBuiltProject(appPath);
    });
    item('flutter run', () async {
      await appShell.run('flutter run');
    });
    if (currentFlavor != null) {
      item('flutter run --flavor <current>', () async {
        await appShell.run('flutter run --flavor $currentFlavor');
      });
    }
    for (var platform in buildPlatformsDesktopAll) {
      item('flutter run -d $platform', () async {
        await appShell.run('flutter run -d $platform');
      });
      if (currentFlavor != null) {
        item('flutter run -d $platform --flavor <current>', () async {
          await appShell
              .run('flutter run -d $platform --flavor $currentFlavor');
        });
      }
    }
  });
  item('list sub projects', () async {
    await recursivePackagesRun([appPath], action: (path) {
      write('project: ${absolute(path)}');
    });
  });
  item('run_ci', () async {
    await packageRunCi(appPath);
  });
  item('pub_get', () async {
    await packageRunCi(appPath, options: PackageRunCiOptions(pubGetOnly: true));
  });
  item('pub_upgrade', () async {
    await packageRunCi(appPath,
        options: PackageRunCiOptions(pubUpgradeOnly: true));
  });
  item('flutter clean', () async {
    if (await checkFlutterSupported()) {
      await appShell.run('flutter clean');
    }
  });
  item('check flutter supported', () async {
    write('Flutter supported: ${await checkFlutterSupported()}');
  });
  item('prompt', () async {
    var command = await prompt('Enter command');
    if (command?.isNotEmpty ?? false) {
      await appShell.run(command!);
    }
  });
}

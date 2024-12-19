import 'dart:convert';
import 'dart:io';

import 'package:dev_build/build_support.dart';
import 'package:dev_build/menu/menu_io.dart';
import 'package:dev_build/package.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart' hide prompt;
import 'package:tekartik_android_utils/aab_utils.dart';
// ignore: depend_on_referenced_packages
import 'package:tekartik_android_utils/build_utils.dart';
import 'package:tekartik_build_flutter/app_builder.dart';
import 'package:tekartik_build_flutter/app_publisher.dart';
import 'package:tekartik_build_flutter/build_flutter.dart';
import 'package:tekartik_common_utils/list_utils.dart'; // ignore: depend_on_referenced_packages

var androidReady = initAndroidBuildEnvironment();

Future main(List<String> arguments) async {
  mainMenuConsole(arguments, menuAppContent);
}

/// To deprecate
void menuAppContent(
    {String path = '.',
    List<String>? flavors,
    AndroidPublisherClient? androidPublisherClient}) {
  var builder = FlutterAppBuilder(
      context: FlutterAppContext(
          path: path, buildOptions: FlutterAppBuildOptions(flavors: flavors)));
  menuFlutterAppContent(
      builder: builder, androidPublisherClient: androidPublisherClient);
}

void menuFlutterAppFlavorContent({
  required FlutterAppFlavorBuilder flavorBuilder,
  AndroidPublisherClient? androidPublisherClient,
}) {
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
      enter(() async {
        await androidReady;
      });
      item('build aab', () async {
        await flavorBuilder.buildAndroidAab();
      });
      item('build apk', () async {
        await flavorBuilder.buildAndroidApk();
      });
      item('sha1', () async {
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
        await flavorBuilder.copyAndroid();
        await printApkSha1();
      });
      if (androidPublisherClient != null) {
        menu('publish menu', () {
          menuFlutterAppFlavorPublish(
              flavorBuilder: flavorBuilder, client: androidPublisherClient);
        });
        item('publish', () async {
          await flavorBuilder.androidPublish(client: androidPublisherClient);
        });
        item('build & publish', () async {
          await flavorBuilder.androidBuildAndPublish(
              client: androidPublisherClient);
        });
        item('clean, build & publish', () async {
          await flavorBuilder.clean();
          await flavorBuilder.androidBuildAndPublish(
              client: androidPublisherClient);
        });
      }
    });
  });
}

/// Menu flutter app publish
void menuFlutterAppFlavorPublish(
    {required FlutterAppFlavorBuilder flavorBuilder,
    required AndroidPublisherClient client}) {
  late ApkInfo apkInfo;
  late AndroidPublisher publisher;
  List<String>? tracksOrNull;

  enter(() async {
    await androidReady;
    apkInfo = await flavorBuilder.getApkInfo();
    publisher = AndroidPublisher(packageName: apkInfo.name!, client: client);
    write(apkInfo);
  });
  Future<List<String>> getTracks({bool force = false}) async {
    if (tracksOrNull == null || force) {
      tracksOrNull = await publisher.listTracks();
    }
    return tracksOrNull!;
  }

  item('list bundles', () async {
    var bundles = await publisher.listBundles();
    write(bundles);
  });
  item('list tracks', () async {
    var tracks = await getTracks(force: true);
    write(tracks);
  });
  item('promote internal to production', () async {
    var internalVersionCode =
        await publisher.getTrackVersionCode(trackName: publishTrackInternal);
    var productionVersionCode =
        await publisher.getTrackVersionCode(trackName: publishTrackProduction);
    write('internal: $internalVersionCode production: $productionVersionCode');
    if ((internalVersionCode ?? 0) > (productionVersionCode ?? 0)) {
      await publisher.publishVersionCode(
          trackName: publishTrackProduction, versionCode: internalVersionCode!);
    }
  });
  item('bundles per tracks', () async {
    var tracks = await getTracks(force: true);
    write(tracks);
    for (var track in tracks) {
      write('track $track');
      try {
        await publisher.getTrackVersionCode(trackName: track);
      } catch (e) {
        write('Error: $e track $track');
      }
    }

    write(tracks);
  });
  item('publish internal', () async {
    await flavorBuilder.androidPublish(
      client: client,
    );
  });
}

void menuFlutterAppContent(
    {required FlutterAppBuilder builder,
    AndroidPublisherClient? androidPublisherClient}) {
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
      if (response.toLowerCase() == 'y') {
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
    if (Platform.isMacOS) {
      menu('ios pod', () {
        var iosPath = normalize(absolute(join(appPath, 'ios')));
        item('Delete podfile.lock && Pods', () async {
          await File(join(iosPath, 'Podfile.lock')).delete(recursive: true);
          await Directory(join(iosPath, 'Pods')).delete(recursive: true);
        });
        item('pod install', () async {
          var shell = Shell().cd(iosPath);
          await shell.run('pod install');
        });
        item('pod install --repo-update', () async {
          var shell = Shell().cd(iosPath);
          await shell.run('pod install --repo-update');
        });
        item('pod repo update', () async {
          var shell = Shell().cd(iosPath);
          await shell.run('pod repo update');
        });
      });
    }
  });
  if (builder.context.buildOptions?.flavors?.isNotEmpty ?? false) {
    menu('flavors', () {
      for (var flavorBuilder in builder.flavorBuilders) {
        menuFlutterAppFlavorContent(
            flavorBuilder: flavorBuilder,
            androidPublisherClient: androidPublisherClient);
      }
    });
  } else {
    menuFlutterAppFlavorContent(
        flavorBuilder: builder.flavorBuilders.first,
        androidPublisherClient: androidPublisherClient);
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
    if (command.isNotEmpty) {
      await appShell.run(command);
    }
  });
}

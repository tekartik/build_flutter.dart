import 'package:dev_test/build_support.dart';
import 'package:dev_test/package.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart' hide prompt;
import 'package:tekartik_build_flutter/build_flutter.dart';
import 'package:tekartik_common_utils/list_utils.dart'; // ignore: depend_on_referenced_packages
import 'package:tekartik_test_menu_io/test_menu_io.dart';

Future main(List<String> arguments) async {
  mainMenu(arguments, menuAppContent);
}

void menuAppContent({String path = '.', List<String>? flavors}) {
  var appPath = path;
  var appShell = Shell(workingDirectory: path);
  var currentFlavor = listFirst(flavors);

  Map pubspec;
  var checkPubspec = () async {
    try {
      pubspec = await pathGetPubspecYamlMap(path);
      return pubspec;
    } catch (_) {}
    return {};
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
    write('App path: ${absolute(path)}');
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
      for (var flavor in flavors!) {
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
    for (var platform in buildSupportedPlatforms) {
      item('create platform project ($platform)', () async {
        if (await checkFlutterSupported()) {
          await createProject(appPath, platform: platform);
        }
      });
    }
  });
  menu('build', () {
    for (var platform in buildSupportedPlatforms) {
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
    await recursivePackagesRun([path], action: (path) {
      write('project: ${absolute(path)}');
    });
  });
  item('run_ci', () async {
    await packageRunCi(path);
  });
  item('pub_get', () async {
    await packageRunCi(path, options: PackageRunCiOptions(pubGetOnly: true));
  });
  item('pub_upgrade', () async {
    await packageRunCi(path,
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

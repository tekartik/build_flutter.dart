import 'package:dev_test/build_support.dart';
import 'package:dev_test/package.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart' hide prompt;
import 'package:tekartik_build_flutter/build_flutter.dart';
import 'package:tekartik_test_menu_io/test_menu_io.dart';

var appPath = '.';
Future main(List<String> arguments) async {
  mainMenu(arguments, menuAppContent);
}

void menuAppContent({String path = '.'}) {
  appPath = path;
  var appShell = Shell(workingDirectory: path);

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
  menu('project', () {
    item('create current platform project ($buildPlatformCurrent)', () async {
      if (await checkFlutterSupported()) {
        await createProject(appPath);
      }
    });
    for (var platform in buildPlatformsAll) {
      item('create platform project ($platform)', () async {
        if (await checkFlutterSupported()) {
          await createProject(appPath, platform: platform);
        }
      });
    }
  });
  menu('build', () {
    item('build web', () async {
      if (await checkFlutterSupported()) {
        await appShell.run('flutter build web');
      }
    });
    item('build android', () async {
      if (await checkFlutterSupported()) {
        await appShell.run('flutter build apk');
      }
    });
    item('build linux', () async {
      if (await checkFlutterSupported()) {
        await appShell.run('flutter build linux');
      }
    });
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
    await packageRunCi(path, options: PackageRunCiOptions(pubGetOnly: true));
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

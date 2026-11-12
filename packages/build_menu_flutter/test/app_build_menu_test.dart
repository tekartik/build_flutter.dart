@TestOn('vm')
library;

// ignore: implementation_imports
import 'package:dev_build/src/menu/dev_menu.dart';
// ignore: implementation_imports
import 'package:dev_build/src/menu/menu.dart' show menuNewDeclarer;
import 'package:tekartik_build_menu_flutter/app_build_menu.dart';
import 'package:test/test.dart';

/// The names of the items and sub menus of [menu].
List<String> _names(DevMenu menu) =>
    menu.items.map((item) => item.name).toList();

/// The sub menu [name] of [menu].
DevMenu _subMenu(DevMenu menu, String name) => menu.items
    .whereType<MenuMenuItem>()
    .firstWhere((item) => item.name == name)
    .menu;

/// The root menu declared by [declare].
DevMenu _declare(void Function() declare) {
  var declarer = menuNewDeclarer()..autoRun = false;
  declare();
  return declarer.devMenu;
}

void main() {
  group('menuFlutterAppContent', () {
    test('one host menu per flavor, named after it', () {
      var root = _declare(() {
        menuFlutterAppContent(
          builder: FlutterAppBuilder(
            context: FlutterAppContext(
              path: 'no_app',
              buildOptions: FlutterAppBuildOptions(flavors: ['dev', 'prod']),
            ),
          ),
        );
      });
      var names = _names(_subMenu(root, 'flavors'));
      expect(names.toSet(), hasLength(names.length), reason: '$names');
      expect(names, [
        'flavor dev',
        'host ($buildPlatformCurrent, dev)',
        'flavor prod',
        'host ($buildPlatformCurrent, prod)',
      ]);
    });

    test('no flavor', () {
      var root = _declare(() {
        menuFlutterAppContent(
          builder: FlutterAppBuilder(
            context: FlutterAppContext(path: 'no_app'),
          ),
        );
      });
      var names = _names(root);
      expect(names, contains('host ($buildPlatformCurrent)'));
      expect(names, isNot(contains('flavors')));
    });
  });
}

import 'package:tekartik_build_menu_flutter/app_build_menu.dart';

/// Flutter device menu
Future<void> main(List<String> args) async {
  await mainMenu(args, () {
    menuFdmContent();
  });
}

import 'package:tekartik_build_menu_flutter/app_build_menu.dart';

Future main(List<String> arguments) async {
  var appPath = '.';
  mainMenuConsole(arguments, () {
    menuAppContent(path: appPath);
  });
}

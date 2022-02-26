import 'package:path/path.dart';
import 'package:tekartik_build_menu_flutter/app_build_menu.dart';

Future main(List<String> arguments) async {
  var appPath = join('..', '..', 'example_flutter', 'app_build_menu_example');
  mainMenu(arguments, () {
    menuAppContent(path: appPath);
  });
}

import 'package:path/path.dart';

import 'package:tekartik_flutter_build/app_build.dart';

var appPath = canonicalize(absolute(join('..', 'app_build_menu_example')));

var appWebBuildOptionsWasm = FlutterWebAppBuildOptions(
  // Wasm not supported yet for google auth
  wasm: true,
  //target: 'lib/main.dart',
);
var appWebDevBuilder = FlutterWebAppBuilder(
  options: FlutterWebAppOptions(
    buildOptions: appWebBuildOptionsWasm,
    path: appPath,
  ),
);
Future<void> main() async {
  await appWebDevBuilder.buildAndServe();
  //await shell.run('flutter run -t lib/main_test_firestore.dart -d chrome --wasm --web-port 8060');
}

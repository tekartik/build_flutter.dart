import 'package:path/path.dart';
import 'package:process_run/shell.dart';

import 'build_and_serve_chrome_wasm.dart';

Future<void> main() async {
  await appWebDevBuilder.run();
  //await shell.run('flutter run -t lib/main_test_firestore.dart -d chrome --wasm --web-port 8060');
}

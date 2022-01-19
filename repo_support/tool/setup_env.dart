import 'dart:io';

import 'package:process_run/shell.dart';

Future<void> main() async {
  if (Platform.isLinux) {
    await Shell().run('tool/setup_linux_env.sh');
  }
}

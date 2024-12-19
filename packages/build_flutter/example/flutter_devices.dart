import 'dart:io';

import 'package:tekartik_build_flutter/flutter_devices.dart';

Future<void> main(List<String> args) async {
  var devices = await getFlutterDevices();
  stdout.writeln(devices.toJsonPretty());
}

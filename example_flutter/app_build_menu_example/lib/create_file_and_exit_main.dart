// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart';

var markerFile =
    join('.dart_tool', 'app_build_menu_example', 'data', 'marker.txt');
Future<void> main() async {
  print('Enter create_file_and_exit');
  try {
    await Directory(dirname(markerFile)).create(recursive: true);
    await File(markerFile).writeAsString(DateTime.now().toIso8601String());
    print('Ok');
    exit(0);
  } catch (e) {
    print('Error $e');
    exit(1);
  }
}

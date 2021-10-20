import 'dart:io';

import 'package:args/args.dart';
import 'package:tekartik_build_flutter/build_flutter.dart';

Future<void> main(List<String> arguments) async {
  var parser = ArgParser();
  parser.addOption('platform', abbr: 'p', help: 'Platform, default to current');
  parser.addMultiOption('platforms', help: 'Platforms, default to current');
  parser.addFlag('help', abbr: 'h', help: 'Usage');

  var result = parser.parse(arguments);
  if (result['help'] as bool) {
    stdout.writeln(
        'Create or recreate a project in the command line for a given platform');
    stdout.writeln('create_project_and_checkout_from_git [<dir>]');
    stdout.writeln(parser.usage);
  }
  if (result.rest.length > 1) {
    stderr.writeln('One argument maximum');
    exit(1);
  }
  var platform = result['platform'] as String?;
  late List<String> platforms;
  if (platform != null) {
    platforms = [platform];
  } else {
    platforms = result['platforms'] as List<String>;
    if (platforms.isEmpty) {
      platforms = [buildPlatformCurrent];
    }
  }

  var dir = result.rest.firstWhere((element) => true, orElse: () => '.');
  for (var platform in platforms) {
    await createProjectAndCheckoutFromGit(dir, platform: platform);
  }
}

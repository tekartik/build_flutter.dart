import 'dart:io';

import 'package:tekartik_build_flutter/build_flutter.dart';

var buildPlatformAndroid = 'android';
var buildPlatformWeb = 'web';
var buildPlatformIOS = 'ios';
var buildPlatformWindows = 'windows';
var buildPlatformMacOS = 'macos';
var buildPlatformLinux = 'linux';

var buildPlatformsAll = [
  buildPlatformAndroid,
  buildPlatformIOS,
  buildPlatformLinux,
  buildPlatformWindows,
  buildPlatformMacOS,
  buildPlatformWeb
];

var buildPlatformsDesktopAll = [
  buildPlatformLinux,
  buildPlatformWindows,
  buildPlatformMacOS,
];

var buildSupportedPlatforms = [
  buildPlatformCurrent,
  buildPlatformWeb,
  if (Platform.isMacOS) buildPlatformIOS,
  buildPlatformAndroid
];
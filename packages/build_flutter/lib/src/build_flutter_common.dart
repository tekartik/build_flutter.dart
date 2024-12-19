import 'package:tekartik_build_flutter/build_flutter.dart';

/// Build platform android
var buildPlatformAndroid = 'android';

/// Build platform web
var buildPlatformWeb = 'web';

/// Build platform ios
var buildPlatformIOS = 'ios';

/// Build platform windows
var buildPlatformWindows = 'windows';

/// Build platform macos
var buildPlatformMacOS = 'macos';

/// Build platform linux
var buildPlatformLinux = 'linux';

/// Build host windows
var buildHostWindows = 'windows';

/// Build host macos
var buildHostMacOS = 'macos';

/// Build host linux
var buildHostLinux = 'linux';

/// ALl build platforms
var buildPlatformsAll = [
  buildPlatformAndroid,
  buildPlatformIOS,
  buildPlatformLinux,
  buildPlatformWindows,
  buildPlatformMacOS,
  buildPlatformWeb
];

/// All desktop build platforms
var buildPlatformsDesktopAll = [
  buildPlatformLinux,
  buildPlatformWindows,
  buildPlatformMacOS,
];

/// All build hosts
var buildHostsAll = [
  buildHostLinux,
  buildHostWindows,
  buildHostMacOS,
];

@Deprecated('Use getBuildHostSupportedPlatforms')

/// Supported build platforms
var buildSupportedPlatforms = getBuildHostSupportedPlatforms();

import 'dart:convert';

import 'package:cv/cv_json.dart';
import 'package:dev_build/shell.dart';

/// [
//   {
//     "name": "sdk gphone64 x86 64",
//     "id": "emulator-5554",
//     "isSupported": true,
//     "targetPlatform": "android-x64",
//     "emulator": true,
//     "sdk": "Android 14 (API 34)",
//     "capabilities": {
//       "hotReload": true,
//       "hotRestart": true,
//       "screenshot": true,
//       "fastStart": true,
//       "flutterExit": true,
//       "hardwareRendering": true,
//       "startPaused": true
//     }
//   },
//   {
//     "name": "Linux",
//     "id": "linux",
//     "isSupported": true,
//     "targetPlatform": "linux-x64",
//     "emulator": false,
//     "sdk": "Ubuntu 24.04.1 LTS 6.8.0-51-generic",
//     "capabilities": {
//       "hotReload": true,
//       "hotRestart": true,
//       "screenshot": false,
//       "fastStart": false,
//       "flutterExit": true,
//       "hardwareRendering": false,
//       "startPaused": true
//     }
//   },
//   {
//     "name": "Chrome",
//     "id": "chrome",
//     "isSupported": true,
//     "targetPlatform": "web-javascript",
//     "emulator": false,
//     "sdk": "Google Chrome 131.0.6778.139",
//     "capabilities": {
//       "hotReload": true,
//       "hotRestart": true,
//       "screenshot": false,
//       "fastStart": false,
//       "flutterExit": false,
//       "hardwareRendering": false,
//       "startPaused": true
//     }
//   }
// ]
/// Flutter device
class FlutterDevice extends CvModelBase {
  /// Name
  final name = CvField<String>('name');

  /// Id
  final id = CvField<String>('id');

  /// Is supported
  final isSupported = CvField<bool>('isSupported');

  /// Target platform
  final targetPlatform = CvField<String>('targetPlatform');

  /// Emulator
  final emulator = CvField<bool>('emulator');

  /// Sdk
  final sdk = CvField<String>('sdk');

  /// Capabilities
  final capabilities = CvField<Map>('capabilities');
  @override
  CvFields get fields =>
      [name, id, isSupported, targetPlatform, emulator, sdk, capabilities];
}

/// Flutter device extension
extension FlutterDeviceExt on FlutterDevice {
  /// Is Android
  bool get isAndroid =>
      targetPlatform.v?.startsWith('android') ?? false; // 'android-x64'

  /// Is Ios
  bool get isIos => targetPlatform.v?.startsWith('ios') ?? false; // 'ios'
}

/// Flutter device capabilities
class FlutterDeviceCapabilities extends CvModelBase {
  /// Hot reload
  final hotReload = CvField<bool>('hotReload');

  /// Hot restart
  final hotRestart = CvField<bool>('hotRestart');

  /// Screenshot
  final screenshot = CvField<bool>('screenshot');

  /// Fast start
  final fastStart = CvField<bool>('fastStart');

  /// Flutter exit
  final flutterExit = CvField<bool>('flutterExit');

  /// Hardware rendering
  final hardwareRendering = CvField<bool>('hardwareRendering');

  /// Start paused
  final startPaused = CvField<bool>('startPaused');
  @override
  CvFields get fields => [
        hotReload,
        hotRestart,
        screenshot,
        fastStart,
        flutterExit,
        hardwareRendering,
        startPaused
      ];
}

/// Get flutter devices
Future<List<FlutterDevice>> getFlutterDevices() async {
  cvAddConstructors([FlutterDevice.new, FlutterDeviceCapabilities.new]);
  var shell = Shell(verbose: false);
  var list = (jsonDecode((await shell.run('flutter devices --machine')).outText)
          as List)
      .cast<Map>()
      .cv<FlutterDevice>();
  return list;
}

/// Helpers
extension FlutterDeviceListExt on List<FlutterDevice> {
  /// Supported only
  List<FlutterDevice> get supported =>
      where((element) => element.isSupported.v ?? false).toList();

  /// Android only
  List<FlutterDevice> get android =>
      where((element) => element.isAndroid).toList();

  /// ios only
  List<FlutterDevice> get ios => where((element) => element.isIos).toList();

  /// To json pretty
  String toJsonPretty() {
    return jsonEncode(map((e) => e.toJson()).toList());
  }
}

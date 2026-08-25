import 'dart:io';

import 'package:path/path.dart';

import 'plist.dart';

/// `com.apple.security.app-sandbox` entitlement key.
///
/// When true (the flutter default) the app runs in the sandbox and cannot
/// execute a binary nor open an arbitrary file.
const macosEntitlementAppSandboxKey = 'com.apple.security.app-sandbox';

/// `com.apple.security.network.client` entitlement key.
///
/// Needed for any outgoing connection (http/https request) when sandboxed.
const macosEntitlementNetworkClientKey = 'com.apple.security.network.client';

/// `com.apple.security.network.server` entitlement key.
///
/// Needed to accept incoming connections when sandboxed.
const macosEntitlementNetworkServerKey = 'com.apple.security.network.server';

/// `com.apple.security.files.user-selected.read-write` entitlement key.
///
/// Allows read/write access to the files explicitly picked by the user when
/// sandboxed.
const macosEntitlementFilesUserSelectedReadWriteKey =
    'com.apple.security.files.user-selected.read-write';

/// Helper for modifying the macos part of a flutter (or dart) project.
///
/// [path] is the project top folder, the one containing the `macos` folder.
///
/// All the modifications are done on the project files (entitlements), they
/// only require the project sources, not a macos host.
class MacosProject {
  /// Project top path, the one containing the `macos` folder.
  final String path;

  /// Constructor, [path] defaults to the current directory.
  MacosProject({String? path}) : path = path ?? '.';

  /// `macos` folder path.
  String get macosPath => join(path, 'macos');

  /// `macos/Runner` folder path.
  String get runnerPath => join(macosPath, 'Runner');

  /// Debug entitlements file path (`macos/Runner/DebugProfile.entitlements`).
  String get debugProfileEntitlementsPath =>
      join(runnerPath, 'DebugProfile.entitlements');

  /// Release entitlements file path (`macos/Runner/Release.entitlements`).
  String get releaseEntitlementsPath =>
      join(runnerPath, 'Release.entitlements');

  /// Debug and release entitlements file paths.
  List<String> get entitlementsPaths => [
    debugProfileEntitlementsPath,
    releaseEntitlementsPath,
  ];

  /// True if the macos project exists.
  bool get exists => Directory(macosPath).existsSync();

  /// Set a boolean entitlement in the entitlements files.
  ///
  /// Both the debug and release entitlements are modified unless [paths] is
  /// specified. Missing files are skipped.
  ///
  /// Returns the list of the modified files.
  Future<List<String>> setBoolEntitlement(
    String key,
    bool value, {
    List<String>? paths,
  }) async {
    var modifiedPaths = <String>[];
    for (var path in paths ?? entitlementsPaths) {
      var plist = PlistFile(path);
      if (!plist.exists) {
        stderr.writeln('missing entitlements file $path');
        continue;
      }
      await plist.read();
      if (plist.setBoolValue(key, value)) {
        await plist.write();
        modifiedPaths.add(path);
        stdout.writeln('$path: $key: $value (modified)');
      } else {
        stdout.writeln('$path: $key: $value (unchanged)');
      }
    }
    return modifiedPaths;
  }

  /// Allow internet access (outgoing http/https requests) for the macos app.
  ///
  /// Adds the `com.apple.security.network.client` entitlement, needed even
  /// when the sandbox is kept enabled. Set [server] to also accept incoming
  /// connections.
  Future<void> allowInternetAccess({bool? server}) async {
    await setBoolEntitlement(macosEntitlementNetworkClientKey, true);
    if (server ?? false) {
      await setBoolEntitlement(macosEntitlementNetworkServerKey, true);
    }
  }

  /// Disable the app sandbox so that the app can execute a binary and open
  /// any file.
  ///
  /// There is no way around the sandbox from the app itself, the
  /// `com.apple.security.app-sandbox` entitlement must be set to false. Such
  /// an app cannot be distributed on the Mac App Store (direct distribution
  /// only).
  ///
  /// The `com.apple.security.files.user-selected.read-write` entitlement is
  /// added as well so that opening a user picked file keeps working if the
  /// sandbox is enabled again later.
  Future<void> disableSandbox() async {
    await setBoolEntitlement(macosEntitlementAppSandboxKey, false);
    await setBoolEntitlement(
      macosEntitlementFilesUserSelectedReadWriteKey,
      true,
    );
  }

  /// Enable the app sandbox back (the flutter default).
  Future<void> enableSandbox() async {
    await setBoolEntitlement(macosEntitlementAppSandboxKey, true);
  }

  /// Write the current entitlements to stdout.
  Future<void> dumpEntitlements() async {
    for (var path in entitlementsPaths) {
      var plist = PlistFile(path);
      if (!plist.exists) {
        stdout.writeln('$path: missing');
        continue;
      }
      await plist.read();
      stdout.writeln('$path:');
      for (var key in plist.keys) {
        stdout.writeln('  $key: ${plist.getValueXml(key)}');
      }
    }
  }

  @override
  String toString() => 'MacosProject(${absolute(normalize(path))})';
}

import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_build_flutter/src/macos_project.dart';
import 'package:tekartik_build_flutter/src/plist.dart';
import 'package:test/test.dart';

var _debugEntitlements = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>com.apple.security.app-sandbox</key>
\t<true/>
\t<key>com.apple.security.cs.allow-jit</key>
\t<true/>
\t<key>com.apple.security.network.server</key>
\t<true/>
</dict>
</plist>
''';

var _releaseEntitlements = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>com.apple.security.app-sandbox</key>
\t<true/>
</dict>
</plist>
''';

/// Create a dummy macos project (entitlements only), returns its top path.
Future<String> _createProject(String name) async {
  var path = join('.dart_tool', 'tekartik_build_flutter', 'test', name);
  var project = MacosProject(path: path);
  await Directory(project.runnerPath).create(recursive: true);
  await File(
    project.debugProfileEntitlementsPath,
  ).writeAsString(_debugEntitlements);
  await File(
    project.releaseEntitlementsPath,
  ).writeAsString(_releaseEntitlements);
  return path;
}

void main() {
  group('macos_project', () {
    test('paths', () {
      var project = MacosProject(path: 'dummy');
      expect(project.macosPath, join('dummy', 'macos'));
      expect(
        project.debugProfileEntitlementsPath,
        join('dummy', 'macos', 'Runner', 'DebugProfile.entitlements'),
      );
      expect(
        project.releaseEntitlementsPath,
        join('dummy', 'macos', 'Runner', 'Release.entitlements'),
      );
      expect(project.exists, isFalse);
    });

    test('allowInternetAccess', () async {
      var project = MacosProject(path: await _createProject('internet'));
      expect(project.exists, isTrue);
      await project.allowInternetAccess();

      for (var path in project.entitlementsPaths) {
        var plist = PlistFile(path);
        await plist.read();
        expect(plist.getBoolValue(macosEntitlementNetworkClientKey), isTrue);
        // Existing entries are kept.
        expect(plist.getBoolValue(macosEntitlementAppSandboxKey), isTrue);
      }
      // The debug file already had the server entitlement.
      var debug = PlistFile(project.debugProfileEntitlementsPath);
      await debug.read();
      expect(debug.getBoolValue(macosEntitlementNetworkServerKey), isTrue);
      expect(debug.keys, [
        macosEntitlementAppSandboxKey,
        'com.apple.security.cs.allow-jit',
        macosEntitlementNetworkServerKey,
        macosEntitlementNetworkClientKey,
      ]);
      expect(await File(project.releaseEntitlementsPath).readAsString(), '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>com.apple.security.app-sandbox</key>
\t<true/>
\t<key>com.apple.security.network.client</key>
\t<true/>
</dict>
</plist>
''');
    });

    test('disableSandbox/enableSandbox', () async {
      var project = MacosProject(path: await _createProject('sandbox'));
      await project.disableSandbox();

      for (var path in project.entitlementsPaths) {
        var plist = PlistFile(path);
        await plist.read();
        expect(plist.getBoolValue(macosEntitlementAppSandboxKey), isFalse);
        expect(
          plist.getBoolValue(macosEntitlementFilesUserSelectedReadWriteKey),
          isTrue,
        );
      }
      expect(await File(project.releaseEntitlementsPath).readAsString(), '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>com.apple.security.app-sandbox</key>
\t<false/>
\t<key>com.apple.security.files.user-selected.read-write</key>
\t<true/>
</dict>
</plist>
''');

      await project.enableSandbox();
      var plist = PlistFile(project.releaseEntitlementsPath);
      await plist.read();
      expect(plist.getBoolValue(macosEntitlementAppSandboxKey), isTrue);
    });

    test('setBoolEntitlement modified', () async {
      var project = MacosProject(path: await _createProject('modified'));
      expect(
        await project.setBoolEntitlement(
          macosEntitlementNetworkClientKey,
          true,
        ),
        project.entitlementsPaths,
      );
      // Already set, nothing to change.
      expect(
        await project.setBoolEntitlement(
          macosEntitlementNetworkClientKey,
          true,
        ),
        isEmpty,
      );
      // Missing file is skipped.
      expect(
        await project.setBoolEntitlement(
          macosEntitlementNetworkClientKey,
          true,
          paths: [join(project.runnerPath, 'Dummy.entitlements')],
        ),
        isEmpty,
      );
    });
  });
}

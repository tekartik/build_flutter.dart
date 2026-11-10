@TestOn('vm')
library;

import 'package:tekartik_build_flutter/bin/create_project_and_checkout_from_git.dart';
import 'package:tekartik_build_flutter/build_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('create_project_and_checkout_from_git', () {
    /// Runs the command, returning the `(path, platform)` it would act on
    /// (nothing is created nor deleted).
    Future<List<(String, String?)>> run(List<String> arguments) async {
      var calls = <(String, String?)>[];
      await createProjectAndCheckoutFromGitCommand(
        arguments,
        createAndCheckout: (path, {platform}) async {
          calls.add((path, platform));
        },
      );
      return calls;
    }

    test('--help only prints the usage', () async {
      expect(await run(['--help']), isEmpty);
      expect(await run(['-h', 'my_app']), isEmpty);
    });

    test('platforms', () async {
      expect(await run([]), [('.', buildPlatformCurrent)]);
      expect(await run(['--platform', 'android', 'my_app']), [
        ('my_app', 'android'),
      ]);
      expect(await run(['--platforms', 'android,web']), [
        ('.', 'android'),
        ('.', 'web'),
      ]);
    });
  });
}

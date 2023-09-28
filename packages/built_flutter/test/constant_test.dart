import 'package:tekartik_built_flutter/constant.dart';
import 'package:test/test.dart';

void main() {
  group('build_flutter', () {
    test('flavor', () {
      expect(envFlavorKey, 'flavor');
    });
  });
}

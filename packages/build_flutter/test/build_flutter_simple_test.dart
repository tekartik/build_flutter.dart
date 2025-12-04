import 'package:tekartik_build_flutter/app_builder.dart';
import 'package:test/test.dart';

void main() {
  group('build', () {
    test('flavors', () {
      var builder = FlutterAppBuilder(
        context: FlutterAppContext(
          buildOptions: FlutterAppBuildOptions(flavors: ['dev', 'prod']),
        ),
      );
      expect(builder.flavorBuilder('dev').flavor, 'dev');
      expect(builder.flavorBuilder('prod').flavor, 'prod');
      expect(() => builder.flavorBuilder(), throwsA(isA<StateError>()));
    });
    test('no flavors', () {
      var builder = FlutterAppBuilder(context: FlutterAppContext());
      expect(builder.flavorBuilder().flavor, isNull);

      expect(() => builder.flavorBuilder('dev'), throwsA(isA<StateError>()));
    });
  });
}

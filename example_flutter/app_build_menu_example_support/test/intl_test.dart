import 'package:tekartik_build_flutter/flutter_project.dart';
import 'package:tekartik_build_flutter/src/text_locale.dart';
import 'package:test/test.dart';

void main() {
  group('intl', () {
    test('checkTranslation', () async {
      var project = FlutterProject('../app_build_menu_example');

      var enMap = await (project.intlLoadLocaleMap(enUsTextLocale));
      var frMap = await project.intlLoadLocaleMap(frFrTextLocale);

      var enUsKeys = Set.from(enMap.keys);

      for (var map in List<Map>.from([frMap])) {
        var keys = Set.from(enUsKeys)..removeAll(map.keys);
        expect(keys, isEmpty, reason: 'locale missing some translations?');
      }
    });
  });
}

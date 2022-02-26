import 'package:dev_test/package.dart';
import 'package:path/path.dart';

Future main() async {
  for (var dir in [
    ...[
      'build_flutter',
      'build_menu_flutter',
    ].map((dir) => join('packages', dir)),
    join('example_flutter', 'app_build_menu_example'),
    join('example_flutter', 'app_build_menu_example_support')
  ]) {
    await packageRunCi(join('..', dir));
  }
}

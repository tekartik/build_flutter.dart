import 'package:dev_test/package.dart';
import 'package:path/path.dart';

Future main() async {
  for (var dir in [
    'build_flutter',
  ]) {
    await packageRunCi(join('..', 'packages', dir));
  }
}

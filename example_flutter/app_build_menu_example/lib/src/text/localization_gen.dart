abstract class AppLocalizationsGen {
  String zzTestCount({required String count}) =>
      t('zzTestCount', {'count': count});
  String get zzzTestLast => t('zzzTestLast');
  String t(String key, [Map<String, String>? data]);
}

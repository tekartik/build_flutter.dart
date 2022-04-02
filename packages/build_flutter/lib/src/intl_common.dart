Map<String, String?> intlFixMap(Map<String, String> map) {
  var newMap = <String, String?>{};
  var keys = map.keys.toList()..sort();
  for (var key in keys) {
    newMap[key] = map[key];
  }
  return newMap;
}

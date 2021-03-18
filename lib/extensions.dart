extension MapUtility<K, V> on Map<K, V> {
  Map<K, V> where(bool Function(K key, V value) test) =>
      Map.fromEntries(entries.where((entry) => test(entry.key, entry.value)));
}
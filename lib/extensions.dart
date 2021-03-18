extension MapUtility<K, V> on Map<K, V> {
  Map<K, V> where(bool Function(K key, V value) test) =>
      Map.fromEntries(entries.where((entry) => test(entry.key, entry.value)));

  void forEachI(void Function(int index, K key, V value) action) {
    var i = 0;
    forEach((k, v) => action(i++, k, v));
  }
}

extension ListUtility<E> on List<E> {
  void forEachI(void Function(int index, E element) action) {
    var i = 0;
    forEach((e) => action(i++, e));
  }
}

import 'dart:io';

String get separator => Platform.pathSeparator;

extension MapUtility<K, V> on Map<K, V> {
  Map<K, V> where(bool Function(K key, V value) test) =>
      Map.fromEntries(entries.where((entry) => test(entry.key, entry.value)));

  void forEachI(void Function(int index, K key, V value) action) {
    var i = 0;
    forEach((k, v) => action(i++, k, v));
  }

  /// Transforms each key of the map. [transform] should return the new key.
  Map<K, V> transformKeys(K Function(K key, V value) transform) =>
      map((k, v) => MapEntry(transform(k, v), v));

  /// Transforms each value of the map. [transform] should return the new value.
  Map<K, V> transformValues(V Function(K key, V value) transform) =>
      map((k, v) => MapEntry(k, transform(k, v)));
}

extension ListUtility<E> on Iterable<E> {
  void forEachI(void Function(int index, E element) action) {
    var i = 0;
    forEach((e) => action(i++, e));
  }

  E safeReduce(E Function(E value, E element) combine) =>
      isEmpty ? null : reduce(combine);
}

extension PathUtils on List<dynamic> {
  String separatorFix() =>
      map((e) => (e is File || e is Directory ? e.path : e) as String)
          .where((str) => str.isNotEmpty)
          .join(separator);

  /// Creates a [File] from the current path.
  /// Replaces all slashes with the division symbol.
  File get file => File(separatorFix());

  /// Creates a [Directory] from the current path.
  /// Replaces all slashes with the division symbol.
  Directory get directory => Directory(separatorFix());
}

extension StringUtils on String {
  int parseInt() => int.tryParse(this);

  double parseDouble() => double.parse(this);

  File get file => File(this);

  Directory get directory => Directory(this);

  Uri get uri => Uri.tryParse(this);
}

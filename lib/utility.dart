import 'dart:convert';

final encoder = JsonEncoder.withIndent('  ');

String prettyEncode(dynamic data) => encoder.convert(data);

/// Provides a function that returns the single parameter, such that
/// ```(e) => e```
E identity<E>(E e) => e;

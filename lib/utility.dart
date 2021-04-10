import 'dart:convert';

import 'package:collection/collection.dart';

final encoder = JsonEncoder.withIndent('  ');

const mapEquality = MapEquality();

String prettyEncode(dynamic data) => encoder.convert(data);

/// Provides a function that returns the single parameter, such that
/// ```(e) => e```
E identity<E>(E e) => e;

/// Provides a function that returns the first parameter, such that
/// ```(_, e) => e```
E identityFirst<E>(E e, dynamic _) => e;

/// Provides a function that returns the second parameter, such that
/// ```(e, _) => e```
E identitySecond<E>(dynamic _, E e) => e;

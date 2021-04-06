import 'package:ondemand_wrapper_gen/extensions.dart';
import 'package:recase/recase.dart';

import 'generate_elements.dart';

/// Checks if the given array's [ElementInfo] arrayInfo contains any
/// non-primitive or non-list types, recursively.
bool containsYuckyChild(ElementInfo arrayInfo) {
  var type = arrayInfo.type;
  if (!type.primitive && type != ElementType.Array) {
    return true;
  }

  if (type == ElementType.Array) {
    return containsYuckyChild(arrayInfo.arrayInfo);
  }

  return false;
}

/// Generated a temporary variable, starting with prefix [name] and ending with
/// the given [depth] if above 0.
String generateTempVar(String name, int depth) {
  if (depth == 0) {
    return name;
  }

  return '$name$depth';
}

/// Takes in an uncasted [List<Map<String, dynamic>>] [data], and aggregates all
/// children of the list to a single [Map<String, dynamic>]
Map<String, dynamic> aggregate(List<dynamic> data) {
  if (data.isEmpty) {
    return {};
  }

  if (data.first.isEmpty) {
    return {};
  }

  if (!(data.first is Map<String, dynamic>)) {
    return simpleAggregate<dynamic, dynamic>(data) as Map<String, dynamic>;
  }

  return simpleAggregate<String, dynamic>(data);
}

Map<K, V> simpleAggregate<K, V>(List<dynamic> data) => data
    .cast<Map<K, V>>()
    .fold(<K, V>{}, (previousValue, element) => {...previousValue, ...element});

/// Aggregates multiple (usually response) objects into one. This only works
/// with a list inside of a list, combining all inner lists. For example, an
/// input may be
/// ```json
/// {
///     "responses": [
///         [
///             {"id": "id", "name":  "name"}
///         ],
///         [
///             {"id": "id1", "name":  "name1"},
///             {"id": "id2", "name":  "name2"}
///         ]
///     ]
/// }
/// ```
/// And the output would be
/// ```json
/// {
///   "responses": [
///     {
///       "id": "id",
///       "name": "name"
///     },
///     {
///       "id": "id1",
///       "name": "name1"
///     },
///     {
///       "id": "id2",
///       "name": "name2"
///     }
///   ]
/// }
/// ```
Map<String, dynamic> doubleAggregate(
    Map<String, dynamic> map) =>
    Map.fromIterables(
        map.keys,
        map.keys.map((key) => (map[key] as List)
            .cast<List>()
            .map((e) => e.cast<Map<String, dynamic>>())
            .map((e) => mergeDeep(e))
            .toList()));

Map<String, dynamic> mergeDeep(List<Map<String, dynamic>> objects) {
  return {
    ...objects.reduce((prev, obj) {
      prev = {...prev};
      obj.keys.forEach((key) {
        var pVal = prev[key];
        var oVal = obj[key];

        if (pVal is List && oVal is List) {
          prev[key] = [...pVal, ...oVal];
        } else if (pVal is Map && oVal is Map) {
          prev[key] = mergeDeep([pVal, oVal]);
        } else {
          prev[key] = oVal;
        }
      });

      return prev;
    })
  };
}

/// Transforms the keys of the map to lowercase.
Map<String, String> lowerCaseKey(Map<String, String> map) =>
    map.transformKeys((k, v) => k.toLowerCase());

/// Returns a function that accepts a [String], transforms it to lowercase,
/// and returns the result of [callback] with the new [String] as a parameter.
String lower(String string, String Function(String) callback) =>
    callback(string.toLowerCase());

/// Formats a string into camelCase
String camel(String string) => ReCase(makeValid(string)).camelCase;

/// Formats a string into PascalCase
String pascal(String string) => ReCase(makeValid(string)).pascalCase;

/// Formats a string into snake-case
String snake(String string) => ReCase(makeValid(string)).snakeCase;

const KEYWORDS = [
  'abstract',
  'else',
  'import',
  'super',
  'as',
  'enum',
  'in',
  'switch',
  'assert',
  'export',
  'interface',
  'sync',
  'async',
  'extends',
  'is',
  'this',
  'await',
  'extension',
  'library',
  'throw',
  'break',
  'external',
  'mixin',
  'true',
  'case',
  'factory',
  'new',
  'try',
  'catch',
  'false',
  'null',
  'typedef',
  'class',
  'final',
  'on',
  'var',
  'const',
  'finally',
  'operator',
  'void',
  'continue',
  'for',
  'part',
  'while',
  'covariant',
  'Function',
  'rethrow',
  'with',
  'default',
  'get',
  'return',
  'yield',
  'deferred',
  'hide',
  'set',
  'do',
  'if',
  'show',
  'dynamic',
  'implements',
  'static',
];

/// Takes in a potentially invalid name and makes it valid for Dart classes
/// or fields. e.g. if `1` is supplied, `Num1` is returned.
String makeValid(String name) {
  if (KEYWORDS.contains(name.toLowerCase())) {
    return '${name}Field';
  }

  name = name.replaceAll(RegExp(r'[^\w]'), '_');

  if (name.startsWith(RegExp(r'\d'))) {
    return 'Num$name';
  }

  return name;
}

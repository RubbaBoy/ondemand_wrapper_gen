import 'dart:core';
import 'dart:core' as core;

import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:recase/recase.dart';

final _formatter = DartFormatter();

/// Generates a Dart class string based on browsing a class tree.
class ClassGenerator {

  final String Function(String) formatOutput;
  final String className;
  final Map<String, dynamic> json;

  ClassGenerator({
    @required this.className,
    @required this.json,
    String Function(String code) formatOutput,
  }) :
        formatOutput = formatOutput ?? _formatter.format;

  String generated() {
    var string = StringBuffer();

    string.writeln(classVisitor(className, json));

    return formatOutput(string.toString());
  }

  String classVisitor(String name, Map<String, dynamic> json) {
    var res = 'class ${pascal(name)} {';

    var types = <MapEntry<String, dynamic>, ElementInfo>{};
    for (var entry in json.entries) {
      types[entry] = ElementInfo.fromElement(entry.value);
    }

    for (var type in types.keys) {
      print('$type: ${types[type]}');
    }

    return '$res}';
  }
}

class ElementInfo {
  final ElementType type;
  final ElementType arrayType;

  /// Sets the base [type]. If the type is an [ElementType.Array], [arrayType]
  /// must be set to the type the array is of.
  ElementInfo(this.type, [this.arrayType]);

  factory ElementInfo.fromElement(dynamic element) {
    var type = ElementType.getType(element);
    if (type == ElementType.Array) {
      return ElementInfo(type, getArrayType(element));
    }

    return ElementInfo(type);
  }

  /// Gets the [ElementType] of the children of a given JSON array (In the form
  /// of a [List]). If there is mismatched types (e.g. number with strings,
  /// numbers with objects, etc.) [ElementType.Object] is used.
  static ElementType getArrayType(List list) {
    var types = list.map((e) => e.runtimeType).toSet();

    if (types.isEmpty) {
      return ElementType.Unknown;
    }

    if (types.length == 1) {
      return ElementType.getType(list.first);
    }

    return ElementType.Object;
  }

  @override
  String toString() => 'ElementInfo{type: $type, arrayType: $arrayType}';
}

class ElementType {
  static final Integer = ElementType._('Integer', type: int);
  static final Double = ElementType._('Double', type: double);
  static final String = ElementType._('String', type: core.String);
  static final Boolean = ElementType._('Boolean', type: bool);
  static final Array = ElementType._('Array', valueTest: (e) => e is List);
  static final Object = ElementType._('Object', valueTest: (_) => true);

  /// Used for objects with no defined type, i.e. empty arrays' types.
  static final Unknown = ElementType._('Unknown', valueTest: (_) => false);

  static final Precedence = <ElementType>[
    Integer,
    Double,
    String,
    Boolean,
    Array,
    Object
  ];

  final core.String name;
  final bool Function(dynamic value) _typeTest;

  /// Creates a [ElementType] with a given [name]. Either [valueTest] or [type]
  /// must be specified. Setting [type] is the same as setting [valueTest] to
  /// ```
  /// (value) => value is type
  /// ```
  ElementType._(this.name, {bool Function(dynamic value) valueTest, Type type})
      : _typeTest = valueTest ?? ((value) => value.runtimeType == type);

  /// Performs a test to check if the [value] is of the current type.
  bool test(dynamic value) => _typeTest(value);

  /// Gets the first matching [ElementType] for the given [value].
  static ElementType getType(dynamic value) =>
      Precedence.firstWhere((element) => element.test(value));

  @override
  core.String toString() => 'ElementType{name: $name}';
}

String camel(String string) => ReCase(string).camelCase;

String pascal(String string) => ReCase(string).pascalCase;

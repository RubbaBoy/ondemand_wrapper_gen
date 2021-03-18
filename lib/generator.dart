import 'dart:core';
import 'dart:core' as core;

import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:recase/recase.dart';

typedef GenerateElement = String Function(String name, ElementInfo info);

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
  }) : formatOutput = formatOutput ?? _formatter.format;

  String generated() {
    var string = StringBuffer();

    string.writeln(classVisitor(className, json));

    var out = string.toString();
    try {
      out = formatOutput(string.toString());
    } catch (e) {
      print(e);
    }

    return out;
  }

  String classVisitor(String name, Map<String, dynamic> json) {
    var res = StringBuffer('class ${pascal(name)} {');

    var types = <MapEntry<String, dynamic>, ElementInfo>{};
    for (var entry in json.entries) {
      var info = ElementInfo.fromElement(entry.value);
      var type = info.type;

      print('$entry: $info');

      res.writeln(type.generate(entry.key, info));
    }

    for (var type in types.keys) {
      print('$type: ${types[type]}');
    }

    res.writeln('}');
    return '$res';
  }
}

class ElementInfo {
  final ElementType type;
  final ElementInfo arrayInfo;

  /// Sets the base [type]. If the type is an [ElementType.Array], [arrayInfo]
  /// must be set to the info of the array.
  ElementInfo(this.type, [this.arrayInfo]);

  /// Creates an [ElementInfo] from a given [element].
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
  static ElementInfo getArrayType(List list) {
    var types = list.map((e) => e.runtimeType).toSet();

    if (types.isEmpty) {
      return ElementInfo(ElementType.Unknown);
    }

    if (types.length == 1) {
      return ElementInfo.fromElement(list.first);
    }

    return ElementInfo(ElementType.Object);
  }

  @override
  String toString() => 'ElementInfo{type: $type, arrayInfo: $arrayInfo}';
}

class ElementType {
  static final Integer = ElementType._('Integer', type: int);

  static final Double = ElementType._('Double', type: double);

  static final String = ElementType._('String', type: core.String);

  static final Boolean = ElementType._('Boolean', type: bool);

  static final Array = ElementType._('Array',
      valueTest: (e) => e is List,
      generateTypeString: (name, info) =>
          'List<${info.arrayInfo.type.generateTypeString(name, info.arrayInfo)}>');

  static final Object =
      ElementType._('Object', valueTest: (_) => true, typeString: 'dynamic');

  /// Used for objects with no defined type, i.e. empty arrays' types.
  static final Unknown =
      ElementType._('Unknown', valueTest: (_) => false, typeString: 'Null');

  /// Sets the order of how the [ElementTypes] are checked, from most specific
  /// to least.
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
  GenerateElement generateTypeString;
  GenerateElement generate;

  /// Creates a [ElementType] with a given [name]. Either [valueTest] or [type]
  /// must be specified. Setting [type] is the same as setting [valueTest] to
  /// ```
  /// (value) => value is type
  /// ```
  /// If no [typeString] is specified, [type] must be set. This is the type
  /// written to Dart programs.
  /// The [generate] is the generator to generate fields. By default it will
  /// return
  /// ```
  /// typeString name;
  /// ```
  ElementType._(this.name,
      {bool Function(dynamic value) valueTest,
      Type type,
      core.String typeString,
      this.generateTypeString,
      this.generate})
      : _typeTest = valueTest ?? ((value) => value.runtimeType == type) {
    generate ??= ((name, info) => '${generateTypeString(name, info)} $name;');
    generateTypeString ??= ((name, _) => typeString ?? type?.toString());
  }

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

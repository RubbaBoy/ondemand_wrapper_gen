import 'dart:core';
import 'dart:core' as core;

import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:ondemand_wrapper_gen/generators.dart';
import 'package:recase/recase.dart';

// /// Used for generating simple code using the Dart name and extra [ElementInfo].
// typedef GenerateJsonSidedCode = String Function(
//     String jsonName, String dartName, ElementInfo info);
//
// /// Used for generating code using the JSON name, Dart name, and extra
// /// [ElementInfo].
// typedef GenerateSimpleCode = String Function(String dartName, ElementInfo info);

/// Used for generating blocks of code, such as fields, methods, constructors,
/// etc... using field data.
typedef BlockGenerator = void Function(
    StringBuffer buffer, ClassContext context, List<ElementInfo> fields);

final _formatter = DartFormatter();

/// Generates a Dart class string based on browsing a class tree.
class ClassGenerator {
  final String Function(String) formatOutput;
  final String className;
  final Map<String, dynamic> json;
  final List<BlockGenerator> extraGenerators;

  /// If [true], classes will be shared among field names. If [false], unique
  /// classes will be created no matter the field repetition.
  ///
  /// [true] by default.
  final bool shareClasses;

  /// Name, Content
  var classes = <String, String>{};

  /// The amount of clashes for a class name
  var clashes = <String, int>{};

  ClassGenerator({
    @required this.className,
    @required this.json,
    String Function(String code) formatOutput,
    this.extraGenerators = const [],
    this.shareClasses = true,
  }) : formatOutput = formatOutput ?? _formatter.format;

  String generated() {
    var string = StringBuffer();

    classVisitor(className, json);

    print('Created classes: ${classes.keys}\n\n');

    classes.values.forEach(string.writeln);

    var out = string.toString();
    try {
      out = formatOutput(string.toString());
    } catch (e) {
      print(e);
    }

    return out;
  }

  void classVisitor(String name, Map<String, dynamic> json) {
    var context = ClassContext(pascal(name));
    var res = StringBuffer('class ${context.name} {');

    var fields = <ElementInfo>[];
    for (var entry in json.entries) {
      fields.add(ElementInfo.fromElement(this,
          singleElement: entry.value, jsonName: entry.key));
    }

    [
      fieldGenerator,
      constructorGenerator,
      fromJson,
      toJson,
      ...extraGenerators,
    ].forEach((generator) {
      generator(res, context, fields);
      res.writeln();
    });

    res.writeln('}');
    classes[name] = res.toString();
  }

  /// Creates a Dart class name in PascalCase from the given JSON field name.
  /// If it would create a duplicate name, if [shareClasses] is true, it will
  /// simply return `null` and no class should be created. If false, it will
  /// append the incrementing number of clashes it has has.
  String createClassName(String jsonName) {
    var name = pascal(jsonName);
    if (className.contains(jsonName)) {
      if (shareClasses) {
        return null;
      }

      clashes.putIfAbsent(name, () => 0);
      name = '$name${++clashes[name]}';
    }

    return name;
  }
}

class ClassContext {
  /// The name of the class.
  final String name;

  ClassContext(this.name);
}

class ElementInfo {
  final String jsonName;
  final String dartName;

  /// Used when the [type] is [ElementType.Object].
  String objectName;

  final ElementType type;
  final ElementInfo arrayInfo;

  /// Sets the base [type]. If the type is an [ElementType.Array], [arrayInfo]
  /// must be set to the info of the array.
  /// The [name] is the name in the JSON the field is. [dartName] is by default
  /// the [jsonName] ran through [camel].
  ElementInfo(this.type,
      {this.jsonName = '', String dartName, this.arrayInfo, this.objectName})
      : dartName = camel(jsonName);

  /// Creates an [ElementInfo] from a given [element].
  /// The [name] is the real variable name.
  /// [allElements] is all elements in the case of the type being a List.
  /// This is because if the type is an [ElementType.Object], the data is
  /// aggregated and the object is created.
  factory ElementInfo.fromElement(ClassGenerator classGenerator,
      {dynamic singleElement,
      List listElement = const [],
      String jsonName = ''}) {
    if (listElement.isEmpty) {
      listElement = [singleElement, ...listElement];
    }

    var element = listElement.first;

    var type = ElementType.getType(element);

    if (type == ElementType.Object) {
      var typeName = classGenerator.createClassName(jsonName);
      classGenerator.classVisitor(typeName, aggregate(listElement));
      return ElementInfo(type, jsonName: jsonName, objectName: typeName);
    }

    if (type == ElementType.Array) {
      return ElementInfo(type,
          jsonName: jsonName, arrayInfo: getArrayType(classGenerator, jsonName, element));
    }

    return ElementInfo(type, jsonName: jsonName);
  }

  /// Takes in an uncasted [List<Map<String, dynamic>>] [data], and aggregates all
  /// children of the list to a single [Map<String, dynamic>]
  static Map<String, dynamic> aggregate(List<dynamic> data) =>
      data.cast<Map<String, dynamic>>().fold(<String, dynamic>{},
          (previousValue, element) => {...previousValue, ...element});

  /// Gets the [ElementType] of the children of a given JSON array (In the form
  /// of a [List]). If there is mismatched types (e.g. number with strings,
  /// numbers with objects, etc.) [ElementType.Mixed] is returned. If the array
  /// is empty, [ElementType.Unknown] is returned.
  static ElementInfo getArrayType(ClassGenerator classGenerator, String jsonName, List list) {
    var types = list.map((e) => e.runtimeType).toSet();

    if (types.isEmpty) {
      return ElementInfo(ElementType.Unknown);
    }

    if (types.length == 1) {
      return ElementInfo.fromElement(classGenerator, jsonName: jsonName, listElement: list);
    }

    return ElementInfo(ElementType.Mixed);
  }

  @override
  String toString() =>
      'ElementInfo{jsonName: $jsonName, dartName: $dartName, objectName: $objectName, type: $type, arrayInfo: $arrayInfo}';
}

class ElementType {
  static final Integer = ElementType._('Integer', type: int);

  static final Double = ElementType._('Double', type: double);

  static final String = ElementType._('String', type: core.String);

  static final Boolean = ElementType._('Boolean', type: bool);

  static final Array = ElementType._('Array',
      valueTest: (e) => e is List,
      generateTypeString: GenerateSimpleCode((dartName, info) =>
          'List<${info.arrayInfo.type.generateTypeString(info.arrayInfo)}>'));

  /// This is a placeholder for new classes being created
  static final Object = ElementType._('Object',
      valueTest: (v) => v is Map,
      generateTypeString:
          GenerateSimpleCode((dartName, info) => info.objectName));

  /// Used for objects with no defined type, i.e. empty arrays' types.
  static final Unknown =
      ElementType._('Unknown', valueTest: (_) => true, typeString: 'Null');

  /// Used for Arrays with mixed child types. This has no precedence as it
  /// should only be manually set.
  static final Mixed =
      ElementType._('Mixed', valueTest: (_) => false, typeString: 'dynamic');

  /// Sets the order of how the [ElementTypes] are checked, from most specific
  /// to least.
  static final Precedence = <ElementType>[
    Integer,
    Double,
    String,
    Boolean,
    Array,
    Object,
    Unknown
  ];

  final core.String name;
  final bool Function(dynamic value) _typeTest;

  /// Generates the [core.String] written to Dart files as the type, such as
  /// String, int, bool, etc.
  GenerateSimpleCode generateTypeString;

  /// Generates the field definition, e.g.
  /// ```
  /// bool foo;
  /// ```
  GenerateSimpleCode generate;

  /// Generates code to convert the variable to JSON. There will always be a
  /// variable named `json` in the scope with the type of `Map<String, dynamic>`
  /// e.g. for converting a string `foo` to JSON:
  /// ```
  /// 'foo': foo
  /// ```
  GenerateJsonSidedCode generateToJson;

  /// Generates code to get the variable from JSON. There will always be a
  /// variable named `json` in the scope with the type of `Map<String, dynamic>`
  /// e.g. for creating a variable `foo` from JSON:
  /// ```
  /// foo = json['foo']
  /// ```
  GenerateJsonSidedCode generateFromJson;

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
  /// If no [generateToJson] is specified, the default is
  /// ```
  /// 'name': name
  /// ```
  /// If no [generateFromJson] is specified, the default is
  /// ```
  /// name = json['name']
  /// ```
  ElementType._(this.name,
      {bool Function(dynamic value) valueTest,
      Type type,
      core.String typeString,
      this.generateTypeString,
      this.generate,
      this.generateToJson,
      this.generateFromJson})
      : _typeTest = valueTest ?? ((value) => value.runtimeType == type) {
    generate ??= GenerateSimpleCode(
        (dartName, info) => '${generateTypeString(info)} $dartName;');
    generateTypeString ??=
        GenerateSimpleCode((dartName, _) => typeString ?? type?.toString());
    generateToJson ??= GenerateJsonSidedCode(
        (jsonName, dartName, info) => "'$jsonName': $dartName");
    generateFromJson ??= GenerateJsonSidedCode(
        (jsonName, dartName, info) => "$dartName = json['$jsonName']");
  }

  /// Performs a test to check if the [value] is of the current type.
  bool test(dynamic value) => _typeTest(value);

  /// Gets the first matching [ElementType] for the given [value].
  static ElementType getType(dynamic value) =>
      Precedence.firstWhere((element) => element.test(value));

  @override
  core.String toString() => 'ElementType{name: $name}';
}

/// Used for generating simple code using the Dart name and extra [ElementInfo].
class GenerateJsonSidedCode {
  final String Function(String jsonName, String dartName, ElementInfo info)
      generate;

  GenerateJsonSidedCode(this.generate);

  String call(ElementInfo info) => generate(info.jsonName, info.dartName, info);
}

/// Used for generating code using the JSON name, Dart name, and extra
/// [ElementInfo].
class GenerateSimpleCode {
  final String Function(String dartName, ElementInfo info) generate;

  GenerateSimpleCode(this.generate);

  String call(ElementInfo info) => generate(info.dartName, info);
}

/// Formats a string into camelCase
String camel(String string) => ReCase(string).camelCase;

/// Formats a string into PascalCase
String pascal(String string) => ReCase(string).pascalCase;

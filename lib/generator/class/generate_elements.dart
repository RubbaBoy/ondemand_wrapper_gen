import 'dart:core';
import 'dart:core' as core;

import 'package:meta/meta.dart';

import 'generate_utils.dart';
import 'generator.dart';

class ElementInfo {
  final String jsonName;
  final String dartName;
  final String jsonPath;

  /// Used when the [type] is [ElementType.Object].
  String objectName;

  final ElementType type;
  final ElementInfo arrayInfo;
  final bool countingKey;

  /// Sets the base [type]. If the type is an [ElementType.Array], [arrayInfo]
  /// must be set to the info of the array.
  /// The [name] is the name in the JSON the field is. [dartName] is by default
  /// the [jsonName] ran through [camel].
  /// [countingKey] is true if the field is generated and should not be
  /// normally serialized.
  ElementInfo._(this.type,
      {@required this.jsonPath,
        this.jsonName = '',
        this.dartName,
        this.arrayInfo,
        this.objectName,
        this.countingKey = false});

  factory ElementInfo(ElementType type,
      {@required ClassGenerator generator,
        @required String parentPath,
        String jsonName = '',
        String dartName,
        ElementInfo arrayInfo,
        String objectName,
        bool countingKey = false}) =>
      ElementInfo._(type,
          jsonPath: '$parentPath#$jsonName',
          jsonName: jsonName,
          dartName: camel(dartName ??
              generator.validateClassName('$parentPath#$jsonName', jsonName)),
          arrayInfo: arrayInfo,
          objectName: objectName,
          countingKey: countingKey);

  /// Creates an [ElementInfo] from a given [element].
  /// The [name] is the real variable name.
  /// [allElements] is all elements in the case of the type being a List.
  /// This is because if the type is an [ElementType.Object], the data is
  /// aggregated and the object is created.
  /// If [forceSeparateArrays] is true, it will force base arrays to become their own
  /// classes.
  /// If [singleElement] is unset, [forceType] must be set.
  factory ElementInfo.fromElement(
      ClassGenerator classGenerator, String jsonPath,
      {dynamic singleElement,
        List listElement = const [],
        String jsonName = '',
        bool forceSeparateArrays = false,
        ElementType forceType,
        String dartName}) {
    if (listElement.isEmpty) {
      listElement = [singleElement, ...listElement];
    }

    var element = listElement.first;

    listElement.removeWhere((e) => e == null);

    var type = ElementType.getType(element) ?? forceType;

    if (type == ElementType.Object) {
      var path = '$jsonPath.$jsonName';
      if (classGenerator.createNewClass(jsonName)) {
        var typeName = classGenerator.createClassName(path, jsonName);
        classGenerator.classVisitor(typeName, aggregate(listElement), path);
      }

      var typeName = classGenerator.createClassName(path, jsonName,
          respectOverflow: false);
      return ElementInfo(type,
          generator: classGenerator,
          parentPath: jsonPath,
          jsonName: jsonName,
          objectName: typeName,
          dartName: dartName);
    }

    if (type == ElementType.Array) {
      var creatingName = jsonName;

      if (element == null) {
        throw 'element must not be null when dealing with arrays';
      }

      var arrayType =
      getArrayType(classGenerator, creatingName, jsonPath, element);

      if (forceSeparateArrays) {
        // Create the outer containing class
        var creatingPath = '$jsonPath.$jsonName'; // jsonName[]
        var containingTypeName =
        classGenerator.createClassName(creatingPath, jsonName);

        // The name of the class being created
        creatingName = classGenerator.createClassName(creatingPath,
            classGenerator.validateArrayClassName(creatingPath, jsonName));

        // If the array's type is an Object, create the inner object
        if (arrayType.type == ElementType.Object) {
          classGenerator.classVisitor(creatingName,
              aggregate(listElement.first), '$creatingPath.$creatingName');

          classGenerator.classVisitor(containingTypeName, {}, creatingPath,
              extraFields: [
                ElementInfo(ElementType.Array,
                    generator: classGenerator,
                    jsonName: jsonName,
                    parentPath: creatingPath,
                    arrayInfo: ElementInfo(ElementType.Object,
                        generator: classGenerator,
                        parentPath: creatingPath,
                        jsonName: creatingName,
                        objectName: creatingName)),
              ]);
        } else {
          // If it's a normal array, simply make the class with an array
          classGenerator.classVisitor(
              creatingName,
              <String, dynamic>{jsonName: <Map<String, dynamic>>[]},
              creatingPath);

          classGenerator.classVisitor(containingTypeName, {}, creatingPath,
              extraFields: [
                ElementInfo.fromElement(classGenerator, creatingPath,
                    singleElement: element, jsonName: jsonName),
              ]);
        }
      }

      var typeName = classGenerator.createClassName(
          '$jsonPath.$creatingName', creatingName,
          respectOverflow: false);
      return ElementInfo(type,
          generator: classGenerator,
          parentPath: jsonPath,
          jsonName: creatingName,
          objectName: typeName,
          arrayInfo: arrayType,
          dartName: dartName);
    }

    return ElementInfo(type,
        generator: classGenerator, parentPath: jsonPath, jsonName: jsonName);
  }

  /// Gets the [ElementType] of the children of a given JSON array (In the form
  /// of a [List]). If there is mismatched types (e.g. number with strings,
  /// numbers with objects, etc.) [ElementType.Mixed] is returned. If the array
  /// is empty, [ElementType.Unknown] is returned.
  static ElementInfo getArrayType(ClassGenerator classGenerator,
      String jsonName, String jsonPath, List list) {
    var types = list.map((e) => e.runtimeType).toSet();

    if (types.isEmpty) {
      return ElementInfo(ElementType.Unknown,
          generator: classGenerator, parentPath: jsonPath);
    }

    if (types.length == 1) {
      return ElementInfo.fromElement(classGenerator, jsonPath,
          jsonName: jsonName, listElement: list);
    }

    return ElementInfo(ElementType.Mixed,
        generator: classGenerator, parentPath: jsonPath);
  }

  @override
  String toString() {
    return 'ElementInfo{jsonName: $jsonName, dartName: $dartName, objectName: $objectName, type: $type, arrayInfo: $arrayInfo, countingKey: $countingKey}';
  }
}

class ElementType {
  static final Integer = ElementType._('Integer', type: int);

  static final Double = ElementType._('Double', type: double);

  static final String = ElementType._('String', type: core.String);

  static final Boolean = ElementType._('Boolean', type: bool);

  static final Array = ElementType._('Array',
      primitive: false,
      valueTest: (e) => e is List,
      generateTypeString: GenerateSimpleCode((dartName, info) =>
      'List<${info.arrayInfo.type.generateTypeString(info.arrayInfo)}>'),
      generateToJson: GenerateJsonSidedCode((jsonName, dartName, info, depth) {
        var arrayType = info.arrayInfo.type;
        if (arrayType.primitive ||
            (arrayType == ElementType.Array &&
                !containsYuckyChild(info.arrayInfo))) {
          return '\$';
        }

        var e = generateTempVar('e', depth);
        return '\$?.map(($e) => ${arrayType.generateToJson(info.arrayInfo).replaceAll('\$', e)})?.toList()';
      }),
      generateFromJson:
      GenerateJsonSidedCode((jsonName, dartName, info, depth) {
        var arrayType = info.arrayInfo.type;
        if (arrayType.primitive) {
          if (arrayType == ElementType.Mixed ||
              arrayType == ElementType.Unknown) {
            return '\$';
          }

          var listDef = depth > 0 ? '(\$ as List)' : '\$';
          return '$listDef?.cast<${arrayType.generateTypeString(info)}>()';
        }

        var e = generateTempVar('e', depth);
        return '(\$ as List)?.map(($e) => ${arrayType.generateFromJson(info.arrayInfo, depth + 1).replaceAll('\$', e)})?.toList()';
      }));

  /// This is a placeholder for new classes being created
  static final Object = ElementType._('Object',
      primitive: false,
      valueTest: (v) => v is Map,
      generateTypeString:
      GenerateSimpleCode((dartName, info) => info.objectName),
      generateToJson:
      GenerateJsonSidedCode((jsonName, dartName, info, _) => '\$?.toJson()'),
      generateFromJson: GenerateJsonSidedCode(
              (jsonName, dartName, info, _) => '${info.objectName}.fromJson(\$ ?? {})'));

  static final KeyedObject = ElementType._('KeyedObject',
      primitive: false,
      valueTest: (_) => false,
      generateTypeString: GenerateSimpleCode((dartName, info) =>
      'List<${info.arrayInfo.type.generateTypeString(info.arrayInfo)}>'),
      generateToJson: GenerateJsonSidedCode((jsonName, dartName, info, depth) {
        var e = generateTempVar('e', depth);
        return 'Map.fromIterables(\$?.map(($e) => $e.getKey()), \$?.map(($e) => ${info.arrayInfo.type.generateToJson(info.arrayInfo, depth + 1).replaceAll('\$', e)}))';
      }),
      generateFromJson:
      GenerateJsonSidedCode((jsonName, dartName, info, depth) {
        var e = generateTempVar('e', depth);
        return 'json.keys.map(($e) => ${info.arrayInfo.type.generateFromJson(info.arrayInfo, depth + 1).replaceAll('\$', '$e, json[$e]')}).toList()';
      }));

  /// Used for objects with no defined type, i.e. empty arrays' types.
  static final Unknown = ElementType._('Unknown',
      primitive: true, valueTest: (_) => true, typeString: 'dynamic');

  /// Used for Arrays with mixed child types. This has no precedence as it
  /// should only be manually set.
  static final Mixed = ElementType._('Mixed',
      primitive: true, valueTest: (_) => false, typeString: 'dynamic');

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
  final bool primitive;
  final bool Function(dynamic value) _typeTest;

  /// Generates the [core.String] written to Dart files as the type, such as
  /// String, int, bool, etc.
  GenerateSimpleCode generateTypeString;

  /// Generates the field definition, e.g.
  /// ```
  /// bool foo;
  /// ```
  GenerateSimpleCode generate;

  /// Generates code to convert the variable to JSON, to proceed the name in a
  /// map, such as `'foo': ` The character `$` will be replaced with the Dart
  /// variable instance. e.g. for converting an object to JSON:
  /// ```
  /// $.toJson()
  /// ```
  GenerateJsonSidedCode generateToJson;

  /// Generates code to get the variable from JSON, to proceed the variable
  /// assignment, such as `foo = ` The character `$` will always be replaced
  /// with a variable in the scope with the type of `Map<String, dynamic>` e.g.
  /// for creating a variable `foo` from JSON (Assuming fromJson accepted a
  /// `Map<String, dynamic>`).
  /// ```
  /// Foo.fromJson($)
  /// ```
  GenerateJsonSidedCode generateFromJson;

  /// Creates a [ElementType] with a given [name]. If the type is primitive to
  /// JSON, [primitive] should be [true]. Either [valueTest] or [type]
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
      {this.primitive = true,
        bool Function(dynamic value) valueTest,
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
    generateToJson ??=
        GenerateJsonSidedCode((jsonName, dartName, info, _) => dartName);
    generateFromJson ??=
        GenerateJsonSidedCode((jsonName, dartName, info, _) => '\$');
  }

  /// Performs a test to check if the [value] is of the current type.
  bool test(dynamic value) => _typeTest(value);

  /// Gets the first matching [ElementType] for the given [value].
  static ElementType getType(dynamic value) => value == null
      ? ElementType.Unknown
      : Precedence.firstWhere((element) => element.test(value));

  @override
  core.String toString() => 'ElementType{name: $name}';
}

/// Used for generating simple code using the Dart name and extra [ElementInfo].
/// The [depth] is how many layers deep the generation is. If it is called once,
/// [depth] is 0. If it's called again from within the generation, it should be
/// 1, etc.
class GenerateJsonSidedCode {
  final String Function(
      String jsonName, String dartName, ElementInfo info, int depth) generate;

  GenerateJsonSidedCode(this.generate);

  String call(ElementInfo info, [int depth = 0]) =>
      generate(info.jsonName, info.dartName, info, depth);
}

/// Used for generating code using the JSON name, Dart name, and extra
/// [ElementInfo].
class GenerateSimpleCode {
  final String Function(String dartName, ElementInfo info) generate;

  GenerateSimpleCode(this.generate);

  String call(ElementInfo info) => generate(info.dartName, info);
}

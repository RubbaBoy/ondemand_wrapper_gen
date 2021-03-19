import 'dart:core';
import 'dart:core' as core;

import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:ondemand_wrapper_gen/extensions.dart';
import 'package:ondemand_wrapper_gen/generators.dart';
import 'package:ondemand_wrapper_gen/utility.dart';
import 'package:recase/recase.dart';

/// Used for generating blocks of code, such as fields, methods, constructors,
/// etc... using field data.
typedef BlockGenerator = void Function(
    StringBuffer buffer, ClassContext context, List<ElementInfo> fields);

/// Generates a block comment at the beginning of a generated class with a
/// given [context].
typedef BlockCommentGenerator = String Function(ClassContext context);

/// Transform a class name
typedef NameTransformer = String Function(String name);

final _formatter = DartFormatter();

/// Generates a Dart class string based on browsing a class tree.
class ClassGenerator {
  final String Function(String) formatOutput;
  String className;
  final Map<String, dynamic> json;
  final bool ignoreBase;
  final bool childrenRequireAggregation;
  final bool forceBaseClasses;
  final List<BlockGenerator> extraGenerators;
  final BlockCommentGenerator commentGenerator;

  /// Allows the mutation of class names. By default, this returns the given
  /// name with no mutations.
  NameTransformer nameTransformer;

  /// Transforms the base class into an array wrapper containing one array
  /// object. If the object was `foo`, this by default would return `foo_array`
  /// and contain one list of `foo`s. The result is automatically formatted to
  /// camelCase or PascalCase, depending on the usage. It is suggested to
  /// separate the name and any appendation it with an underscore.
  NameTransformer arrayTransformer;

  /// Allows the mutation of single-field array classes' names.
  NameTransformer arrayFieldTransformer;

  /// If [true], classes will be shared among field names. If [false], unique
  /// classes will be created no matter the field repetition.
  ///
  /// [true] by default.
  final bool shareClasses;

  /// If [true], all generated fields will be final.
  final bool finalizeFields;

  /// Name, Content
  var classes = <String, String>{};

  /// The amount of clashes for a class name
  var clashes = <String, int>{};

  /// The [statusNameTransformer] takes precedence over the supplied or default
  /// [nameTransformer], replacing the key names with the values.
  /// The [staticArrayTransformer] takes precedence over the supplied or
  /// default [arrayTransformer], replacing the key names with the values.
  /// The [staticArrayFieldTransformer] takes precedence over the supplied or
  /// default [arrayFieldTransformer], replacing the key names with the values.
  /// [childrenRequireAggregation] must be set to true if the input is in the
  /// form of members with arrays of multiple responses. This simply invokes
  /// [aggregateMultiple] on each field of the input JSON before conversion.
  /// [forceBaseClasses] forces all base fields to be classes. Primarily, if a
  /// base field is an array, it will create a class with a single array in it.
  /// [ignoreBase] ignores the base class, parsing all member classes.
  /// [finalizeFields] sets if all generated fields should be final.
  ClassGenerator({
    @required this.json,
    String className,
    this.childrenRequireAggregation = false,
    this.forceBaseClasses = false,
    this.ignoreBase = false,
    String Function(String code) formatOutput,
    this.extraGenerators = const [],
    this.shareClasses = true,
    this.finalizeFields = true,
    this.commentGenerator,
    NameTransformer nameTransformer,
    NameTransformer arrayTransformer,
    NameTransformer arrayFieldTransformer,
    Map<String, String> staticNameTransformer = const {},
    Map<String, String> staticArrayTransformer = const {},
    Map<String, String> staticArrayFieldTransformer = const {},
  }) : formatOutput = formatOutput ?? _formatter.format {
    this.className = className ?? 'Clazz$hashCode';

    staticNameTransformer = lowerCaseKey(staticNameTransformer);
    staticArrayTransformer = lowerCaseKey(staticArrayTransformer);
    staticArrayFieldTransformer = lowerCaseKey(staticArrayFieldTransformer);

    var backupNameTransformer = nameTransformer ?? identity;
    this.nameTransformer = (name) =>
        staticNameTransformer[name.toLowerCase()] ??
        backupNameTransformer(name);

    var backupArrayTransformer = arrayTransformer ?? (name) => name + '_array';
    this.arrayTransformer = (name) =>
        staticArrayTransformer[name.toLowerCase()] ??
        backupArrayTransformer(name);

    var backupArrayFieldTransformer = arrayFieldTransformer ?? identity;
    this.arrayFieldTransformer = (name) =>
        staticArrayFieldTransformer[name.toLowerCase()] ??
        backupArrayFieldTransformer(name);
  }

  String generated() {
    var string = StringBuffer();

    if (childrenRequireAggregation) {
      var aggregated = json.map<String, MapEntry<dynamic, bool>>((key, value) {
        var requireArray = false;
        var redone = value;
        if (!(value is List)) {
          throw 'All member should be lists!';
        }
        var list = value as List;
        var first = list.isNotEmpty ? list.first : null;
        if (first is Map) {
          if (first.isEmpty) {
            redone = <String, dynamic>{};
          } else {
            redone = aggregate(list);
          }
        } else if (first is List) {
          redone = doubleAggregate({key: list});
          requireArray = true;
        }
        return MapEntry(key, MapEntry(redone, requireArray));
      });

      for (var jsonName in aggregated.keys) {
        var entry = aggregated[jsonName];
        var requireArray = entry.value;
        var className =
            requireArray ? validateArrayClassName(jsonName) : jsonName;

        classVisitor(className, entry.key,
            base: true, forceBaseClasses: false, arrayClass: entry.value);
      }
    } else {
      classVisitor(className, json,
          base: true, forceBaseClasses: forceBaseClasses);
    }

    print('Created classes: ${classes.keys.join(', ')}\n\n');

    classes.values.forEach(string.writeln);

    var out = string.toString();
    try {
      out = formatOutput(string.toString());
    } catch (e) {
      print(e);
    }

    return out;
  }

  /// Creates classes and adds them into [classes] with the given [name] and
  /// [json] content. [base] should only be [true] for the first class created.
  /// If both that and [ignoreBase] is [true], the class is not printed, however
  /// member classes are.
  /// The [extraFields] is for a manual addition of fields to the class, in the
  /// case of something like adding a manual Array of a custom type.
  /// [arrayClass] sets the [fromJson] [JsonType] to [JsonType.Object].
  void classVisitor(String name, Map<String, dynamic> json,
      {bool base = false,
      List<ElementInfo> extraFields = const [],
      bool forceBaseClasses,
      bool arrayClass = false,
      String overrideClassName}) {
    forceBaseClasses ??= this.forceBaseClasses;
    var context = ClassContext(createClassName(overrideClassName ?? name));
    var comment = commentGenerator?.call(context);
    if (comment != null) {
      comment = comment
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map((e) => '/// $e')
          .join('\n');
    }
    var res = StringBuffer(comment ?? '');
    res.writeln('\nclass ${context.name} {');

    var fields = extraFields.toList();
    for (var entry in json.entries) {
      var jsonName = entry.key;
      var dartName;
      if (arrayClass) {
        dartName = validateArrayFieldName(jsonName);
      }

      fields.add(ElementInfo.fromElement(this,
          forceSeparateArrays: base && forceBaseClasses,
          singleElement: entry.value,
          jsonName: jsonName,
          dartName: dartName));
    }

    var jsonType = arrayClass ? JsonType.Array : JsonType.Object;

    [
      (buffer, context, fields) =>
          fieldGenerator(buffer, context, fields, finalizeFields),
      constructorGenerator,
      (buffer, context, fields) => fromJson(buffer, context, fields, jsonType),
      (buffer, context, fields) => toJson(buffer, context, fields, jsonType),
      ...extraGenerators,
    ].forEach((generator) {
      generator(res, context, fields);
      res.writeln();
    });

    res.writeln('}');

    if (!base || !(base && ignoreBase)) {
      classes[name.toLowerCase()] = res.toString();
    } else {
      print('Not registering class: $name');
    }
  }

  /// Returns if a new class should be created.
  /// If it would create a duplicate name, if [shareClasses] is true, it will
  /// simply return `null` and no class should be created.
  bool createNewClass(String jsonName) {
    if (classes.containsKey(jsonName) && shareClasses) {
      return false;
    }

    return true;
  }

  /// Creates a Dart class name in PascalCase from the given JSON field name.
  /// Ignores [sharedClasses]. If [respectDuplicates] is true and it would be a
  /// duplicate, it will append the incrementing number of clashes it has has.
  String createClassName(String jsonName, {bool respectOverflow = true}) {
    var name = pascal(jsonName);
    if (classes.containsKey(jsonName) && respectOverflow) {
      clashes.putIfAbsent(name, () => 0);
      name = '$name${++clashes[name]}';
    }

    return pascal(validateClassName(name));
  }

  /// Transforms a class name if necessary.
  String validateClassName(String name) => nameTransformer(name);

  /// Transforms an array class name if necessary.
  String validateArrayClassName(String name) => arrayTransformer(name);

  /// Transforms an array field name if necessary.
  String validateArrayFieldName(String name) => arrayFieldTransformer(name);
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
      : dartName = dartName ?? camel(jsonName);

  /// Creates an [ElementInfo] from a given [element].
  /// The [name] is the real variable name.
  /// [allElements] is all elements in the case of the type being a List.
  /// This is because if the type is an [ElementType.Object], the data is
  /// aggregated and the object is created.
  /// If [forceSeparateArrays] is true, it will force base arrays to become their own
  /// classes.
  /// If [singleElement] is unset, [forceType] must be set.
  factory ElementInfo.fromElement(ClassGenerator classGenerator,
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
      if (classGenerator.createNewClass(jsonName)) {
        var typeName = classGenerator.createClassName(jsonName);
        classGenerator.classVisitor(typeName, aggregate(listElement));
      }

      var typeName =
          classGenerator.createClassName(jsonName, respectOverflow: false);
      return ElementInfo(type,
          jsonName: jsonName, objectName: typeName, dartName: dartName);
    }

    if (type == ElementType.Array) {
      var creatingName = jsonName;

      if (element == null) {
        throw 'element must not be null when dealing with arrays';
      }

      var arrayType = getArrayType(classGenerator, creatingName, element);

      if (forceSeparateArrays) {
        // Create the outer containing class
        var containingTypeName = classGenerator.createClassName(jsonName);

        // The name of the class being created
        creatingName = classGenerator
            .createClassName(classGenerator.validateArrayClassName(jsonName));

        // If the array's type is an Object, create the inner object
        if (arrayType.type == ElementType.Object) {
          classGenerator.classVisitor(
              creatingName, aggregate(listElement.first));

          classGenerator.classVisitor(containingTypeName, {}, extraFields: [
            ElementInfo(ElementType.Array,
                jsonName: jsonName,
                arrayInfo: ElementInfo(ElementType.Object,
                    jsonName: creatingName, objectName: creatingName)),
          ]);
        } else {
          // If it's a normal array, simply make the class with an array
          classGenerator.classVisitor(creatingName,
              <String, dynamic>{jsonName: <Map<String, dynamic>>[]});

          classGenerator.classVisitor(containingTypeName, {}, extraFields: [
            ElementInfo.fromElement(classGenerator,
                singleElement: element, jsonName: jsonName),
          ]);
        }
      }

      var typeName =
          classGenerator.createClassName(creatingName, respectOverflow: false);
      return ElementInfo(type,
          jsonName: creatingName,
          objectName: typeName,
          arrayInfo: arrayType,
          dartName: dartName);
    }

    return ElementInfo(type, jsonName: jsonName);
  }

  /// Gets the [ElementType] of the children of a given JSON array (In the form
  /// of a [List]). If there is mismatched types (e.g. number with strings,
  /// numbers with objects, etc.) [ElementType.Mixed] is returned. If the array
  /// is empty, [ElementType.Unknown] is returned.
  static ElementInfo getArrayType(
      ClassGenerator classGenerator, String jsonName, List list) {
    var types = list.map((e) => e.runtimeType).toSet();

    if (types.isEmpty) {
      return ElementInfo(ElementType.Unknown);
    }

    if (types.length == 1) {
      return ElementInfo.fromElement(classGenerator,
          jsonName: jsonName, listElement: list);
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
        return '\$.map(($e) => ${arrayType.generateToJson(info.arrayInfo).replaceAll('\$', e)}).toList()';
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
          return '$listDef.cast<${arrayType.generateTypeString(info)}>()';
        }

        var e = generateTempVar('e', depth);
        return '(\$ as List).map(($e) => ${arrayType.generateFromJson(info.arrayInfo, depth + 1).replaceAll('\$', e)}).toList()';
      }));

  /// This is a placeholder for new classes being created
  static final Object = ElementType._('Object',
      primitive: false,
      valueTest: (v) => v is Map,
      generateTypeString:
          GenerateSimpleCode((dartName, info) => info.objectName),
      generateToJson:
          GenerateJsonSidedCode((jsonName, dartName, info, _) => '\$.toJson()'),
      generateFromJson: GenerateJsonSidedCode(
          (jsonName, dartName, info, _) => '${info.objectName}.fromJson(\$)'));

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
      ? null
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
  return objects.reduce((prev, obj) {
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
  });
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

/// Takes in a potentially invalid name and makes it valid for Dart classes
/// or fields. e.g. if `1` is supplied, `Num1` is returned.
String makeValid(String name) {
  if (name.startsWith(RegExp(r'\d'))) {
    return 'Num$name';
  }

  return name;
}

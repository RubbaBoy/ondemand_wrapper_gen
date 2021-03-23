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

/// Transform a class name. Takes in the JSON path and the name of the class.
typedef NameTransformer = String Function(String path, String name);

final _formatter = DartFormatter();

/// Generates a Dart class string based on browsing a class tree.
class ClassGenerator {
  final String Function(String) formatOutput;
  String className;
  final String url;
  final String method;
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

  /// If [true], classes will be shared among field names. If [false], unique
  /// classes will be created no matter the field repetition.
  ///
  /// [true] by default.
  final bool shareClasses;

  /// If [true], all generated fields will be final.
  final bool finalizeFields;

  /// If [staticArrayTransformer] should be replaced with
  /// [staticNameTransformer].
  final bool combineNameTransformers;

  /// The JSON path of the object containing multiple objects, all with names
  /// as a number. This will force ALL children members into a single object.
  /// For example:
  /// ```json
  /// {
  ///   "foo": {
  ///     "1": {
  ///       "name": "Bar"
  ///     }
  ///   }
  /// }
  /// ```
  /// The path would be `foo` and `foo.1` would be turned into an object with
  /// the name 1. Used for varying dynamic keys.
  final List<String> forceObjectCounting;

  /// Name, Content
  final classes = <String, String>{};

  /// The amount of clashes for a class name
  final clashes = <String, int>{};

  /// The [staticNameTransformer] takes precedence over the supplied or default
  /// [nameTransformer], replacing the key names with the values.
  /// The [staticArrayTransformer] takes precedence over the supplied or
  /// default [arrayTransformer], replacing the key names with the values.
  /// If [staticArrayTransformer] is empty, it is set to [staticNameTransformer].
  /// [childrenRequireAggregation] must be set to true if the input is in the
  /// form of members with arrays of multiple responses. This simply invokes
  /// [aggregateMultiple] on each field of the input JSON before conversion.
  /// [forceBaseClasses] forces all base fields to be classes. Primarily, if a
  /// base field is an array, it will create a class with a single array in it.
  /// [ignoreBase] ignores the base class, parsing all member classes.
  /// [finalizeFields] sets if all generated fields should be final.
  ClassGenerator({
    this.className = 'BaseClass',
    this.url,
    this.method,
    this.childrenRequireAggregation = false,
    this.forceBaseClasses = false,
    this.ignoreBase = false,
    String Function(String code) formatOutput,
    this.extraGenerators = const [],
    this.shareClasses = true,
    this.finalizeFields = true,
    this.combineNameTransformers = false,
    this.commentGenerator,
    NameTransformer nameTransformer,
    NameTransformer arrayTransformer,
    Map<String, String> staticNameTransformer = const {},
    Map<String, String> staticArrayTransformer = const {},
    this.forceObjectCounting = const [],
  }) : formatOutput = formatOutput ?? _formatter.format {

    var backupNameTransformer = nameTransformer ?? identitySecond;
    this.nameTransformer = (path, name) =>
        staticNameTransformer[path] ?? backupNameTransformer(path, name);

    if (combineNameTransformers) {
      arrayTransformer = nameTransformer;
    } else {
      var backupArrayTransformer =
          arrayTransformer ?? (_, name) => name + '_array';
      this.arrayTransformer = (path, name) =>
      staticArrayTransformer[path] ?? backupArrayTransformer(path, name);
    }
  }

  factory ClassGenerator.fromSettings(GeneratorSettings settings) =>
      ClassGenerator(
          className: settings.className,
          url: settings.url,
          method: settings.method,
          childrenRequireAggregation: settings.childrenRequireAggregation,
          forceBaseClasses: settings.forceBaseClasses,
          ignoreBase: settings.ignoreBase,
          formatOutput: settings.formatOutput,
          extraGenerators: settings.extraGenerators,
          shareClasses: settings.shareClasses,
          finalizeFields: settings.finalizeFields,
          combineNameTransformers: settings.combineNameTransformers,
          commentGenerator: settings.commentGenerator,
          nameTransformer: settings.nameTransformer,
          arrayTransformer: settings.arrayTransformer,
          staticNameTransformer: settings.staticNameTransformer,
          staticArrayTransformer: settings.staticArrayTransformer,
          forceObjectCounting: settings.forceObjectCounting);

  String generated(Map<String, dynamic> json) {
    json = Map.unmodifiable(json);
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
          var firstEntry = doubleAggregate({key: list}).entries.first;
          var firstList = firstEntry.value as List;
          redone = {
            firstEntry.key: [mergeDeep(firstList.cast<Map<String, dynamic>>())]
          };
          requireArray = true;
        }
        return MapEntry(key, MapEntry(redone, requireArray));
      });

      // print(prettyEncode(aggregated.map((key, value) => MapEntry(key, value.key))));

      for (var jsonName in aggregated.keys) {
        var entry = aggregated[jsonName];
        var requireArray = entry.value;
        var className = requireArray
            ? validateArrayClassName(jsonName, jsonName)
            : jsonName;

        classVisitor(className, entry.key, jsonName,
            base: true, forceBaseClasses: false, arrayClass: requireArray);
      }
    } else {
      classVisitor(className, json, '',
          base: true, forceBaseClasses: forceBaseClasses);
    }

    print(
        'Created classes (${classes.length}): ${classes.keys.join(', ')}\n\n');

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
  /// [countingObject] If the object's key is a dynamic number, requiring
  /// additional serialization data.
  void classVisitor(String name, Map<String, dynamic> json, String jsonPath,
      {bool base = false,
      List<ElementInfo> extraFields = const [],
      bool forceBaseClasses,
      bool arrayClass = false,
      String overrideClassName,
      bool countingObject = false}) {
    forceBaseClasses ??= this.forceBaseClasses;
    var contextPath = cleanPath(jsonPath);
    var context = ClassContext(
        createClassName(contextPath, overrideClassName ?? name),
        url,
        method,
        contextPath);
    print('Creating class "${context.name}" path = $jsonPath');
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
    if (forceObjectCounting.contains(cleanPath(jsonPath))) {
      var deep = mergeDeep(json.values.cast<Map<String, dynamic>>().toList());
      var creatingPath = '$jsonPath[]';
      var creatingName = createClassName(
          creatingPath, validateClassName(creatingPath, '${context.name}_num'));

      // Turn deep into an array object holding a custom class in fields

      var keyName = nonClashingFieldName(deep, 'key');
      classVisitor(creatingName, deep, creatingPath,
          countingObject: true,
          extraFields: [
            ElementInfo(ElementType.String,
                generator: this,
                parentPath: creatingPath,
                jsonName: keyName,
                countingKey: true),
          ]);

      fields.add(ElementInfo(ElementType.KeyedObject,
          generator: this,
          parentPath: jsonPath,
          jsonName: camel(name),
          arrayInfo: ElementInfo(ElementType.Object,
              generator: this,
              parentPath: jsonPath,
              jsonName: creatingName,
              objectName: creatingName)));
    } else {
      for (var entry in json.entries) {
        var jsonName = entry.key;
        var dartName;
        if (arrayClass) {
          dartName = validateClassName('$jsonPath#$jsonName', jsonName);
        }

        fields.add(ElementInfo.fromElement(this, jsonPath,
            forceSeparateArrays: base && forceBaseClasses,
            singleElement: entry.value,
            jsonName: jsonName,
            dartName: dartName));
      }
    }

    var jsonType = JsonType.Object;
    if (countingObject) {
      jsonType = JsonType.KeyedObject;
    } else if (arrayClass) {
      jsonType = JsonType.Array;
    }

    [
      (buffer, context, fields) =>
          fieldGenerator(buffer, context, fields, finalizeFields),
      constructorGenerator,
      (buffer, context, fields) => getKey(buffer, context, fields, jsonType),
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

  /// Mutates [name] so it doesn't clash with any key in [json], by appending a
  /// number to the end. The new name is returned to use.
  String nonClashingFieldName(Map<String, dynamic> json, String name) {
    if (!json.keys.contains(name)) {
      return name;
    }

    return nonClashingFieldName(json, '${name}1');
  }

  /// Removes the initial `.` of a json path
  String cleanPath(String jsonPath) {
    if (jsonPath.startsWith('.')) {
      return jsonPath.substring(1);
    }
    return jsonPath;
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
  String createClassName(String path, String jsonName,
      {bool respectOverflow = true}) {
    var name = pascal(jsonName);
    if (classes.containsKey(jsonName) && respectOverflow) {
      clashes.putIfAbsent(name, () => 0);
      name = '$name${++clashes[name]}';
    }

    return pascal(validateClassName(path, name));
  }

  /// Transforms a class name if necessary. Replaces non alphanumeric (and
  /// underscores) characters with underscores.
  String validateClassName(String path, String name) =>
      nameTransformer(path, name);

  /// Transforms an array class name if necessary.
  String validateArrayClassName(String path, String name) =>
      arrayTransformer(path, name);
}

/// The settings for [ClassGenerator]s.
class GeneratorSettings {
  final String className;
  final String url;
  final String method;
  final bool childrenRequireAggregation;
  final bool forceBaseClasses;
  final bool ignoreBase;
  final String Function(String code) formatOutput;
  final List<BlockGenerator> extraGenerators;
  final bool shareClasses;
  final bool finalizeFields;
  final bool combineNameTransformers;
  final BlockCommentGenerator commentGenerator;
  final NameTransformer nameTransformer;
  final NameTransformer arrayTransformer;
  final Map<String, String> staticNameTransformer;
  final Map<String, String> staticArrayTransformer;
  final List<String> forceObjectCounting;

  /// Creates a [GeneratorSettings] with the default values.
  factory GeneratorSettings.defaultSettings() => GeneratorSettings(
        className: 'BaseClass',
        childrenRequireAggregation: false,
        forceBaseClasses: false,
        ignoreBase: false,
        extraGenerators: const [],
        shareClasses: true,
        finalizeFields: true,
        combineNameTransformers: false,
        staticNameTransformer: const {},
        staticArrayTransformer: const {},
        forceObjectCounting: const [],
      );

  /// Creates a [GeneratorSettings] with all null values. Suggested as the
  /// second parameter for [GeneratorSettings.mergeSettings] (So the fallback
  /// can set default values)
  const GeneratorSettings(
      {this.className,
      this.url,
      this.method,
      this.childrenRequireAggregation,
      this.forceBaseClasses,
      this.ignoreBase,
      this.formatOutput,
      this.extraGenerators,
      this.shareClasses,
      this.finalizeFields,
      this.combineNameTransformers,
      this.commentGenerator,
      this.nameTransformer,
      this.arrayTransformer,
      this.staticNameTransformer,
      this.staticArrayTransformer,
      this.forceObjectCounting});

  /// Creates a [GeneratorSettings] with the same values as [merging] but in
  /// the case of null values, using [fallback].
  factory GeneratorSettings.mergeSettings(
          GeneratorSettings merging, GeneratorSettings fallback) =>
      GeneratorSettings(
        className: merging.className ?? fallback.className,
        url: merging.url ?? fallback.url,
        method: merging.method ?? fallback.method,
        childrenRequireAggregation: merging.childrenRequireAggregation ??
            fallback.childrenRequireAggregation,
        forceBaseClasses: merging.forceBaseClasses ?? fallback.forceBaseClasses,
        ignoreBase: merging.ignoreBase ?? fallback.ignoreBase,
        formatOutput: merging.formatOutput ?? fallback.formatOutput,
        extraGenerators: merging.extraGenerators ?? fallback.extraGenerators,
        shareClasses: merging.shareClasses ?? fallback.shareClasses,
        finalizeFields: merging.finalizeFields ?? fallback.finalizeFields,
        combineNameTransformers: merging.combineNameTransformers ?? fallback.combineNameTransformers,
        commentGenerator: merging.commentGenerator ?? fallback.commentGenerator,
        nameTransformer: merging.nameTransformer ?? fallback.nameTransformer,
        arrayTransformer: merging.arrayTransformer ?? fallback.arrayTransformer,
        staticNameTransformer:
            merging.staticNameTransformer ?? fallback.staticNameTransformer,
        staticArrayTransformer:
            merging.staticArrayTransformer ?? fallback.staticArrayTransformer,
        forceObjectCounting:
            merging.forceObjectCounting ?? fallback.forceObjectCounting,
      );

  /// The same as merging settings with the [merging] be [newValues] and the
  /// fallback being the current [GeneratorSettings]. It's suggested to start
  /// with a [GeneratorSettings.empty] for [newValue].
  ///
  /// The [fallback], if set, will replace any [null] values.
  GeneratorSettings copyWith({
    String className,
    String url,
    String method,
    bool childrenRequireAggregation,
    bool forceBaseClasses,
    bool ignoreBase,
    String Function(String code) formatOutput,
    List<BlockGenerator> extraGenerators,
    bool shareClasses,
    bool finalizeFields,
    bool combineNameTransformers,
    BlockCommentGenerator commentGenerator,
    NameTransformer nameTransformer,
    NameTransformer arrayTransformer,
    Map<String, String> staticNameTransformer,
    Map<String, String> staticArrayTransformer,
    List<String> forceObjectCounting,
  }) =>
      GeneratorSettings.mergeSettings(
          GeneratorSettings(
            className: className,
            url: url,
            method: method,
            childrenRequireAggregation: childrenRequireAggregation,
            forceBaseClasses: forceBaseClasses,
            ignoreBase: ignoreBase,
            formatOutput: formatOutput,
            extraGenerators: extraGenerators,
            shareClasses: shareClasses,
            finalizeFields: finalizeFields,
            combineNameTransformers: combineNameTransformers,
            commentGenerator: commentGenerator,
            nameTransformer: nameTransformer,
            arrayTransformer: arrayTransformer,
            staticNameTransformer: staticNameTransformer,
            staticArrayTransformer: staticArrayTransformer,
            forceObjectCounting: forceObjectCounting,
          ),
          this);
}

class ClassContext {
  /// The name of the class..
  final String name;

  /// The URL used for the request/receiving body.
  final String url;

  /// The HTTP method in the request.
  final String method;

  /// The json path of the class
  final String jsonPath;

  ClassContext(this.name, this.url, this.method, this.jsonPath);
}

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

  static final KeyedObject = ElementType._('KeyedObject',
      primitive: false,
      valueTest: (_) => false,
      generateTypeString: GenerateSimpleCode((dartName, info) =>
          'List<${info.arrayInfo.type.generateTypeString(info.arrayInfo)}>'),
      generateToJson: GenerateJsonSidedCode((jsonName, dartName, info, depth) {
        var e = generateTempVar('e', depth);
        return 'Map.fromIterables(\$.map(($e) => $e.getKey()), \$.map(($e) => ${info.arrayInfo.type.generateToJson(info.arrayInfo, depth + 1).replaceAll('\$', e)}))';
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

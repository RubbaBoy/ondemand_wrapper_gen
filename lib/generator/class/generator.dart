import 'dart:core';
import 'dart:core' as core;

import 'package:dart_style/dart_style.dart';
import 'package:ondemand_wrapper_gen/generator/class/generators.dart';
import 'package:ondemand_wrapper_gen/utility.dart';

import 'generate_elements.dart';
import 'generate_utils.dart';

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
  final String className;
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

  /// If there is no request or response body for the given request. (And if the
  /// response both should be ignored)
  final bool unbodiedResponse;

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

  /// Forces the given list of JSON path fields to have `#toString()` invoked
  /// upon them before setting them to a field. This is to help combat
  /// inconsistencies of ints and strings present in the Agilysys OnDemand API.
  final List<String> forceToString;

  /// Forces the separation of classes with a JSON path in the list.
  final List<String> forceSeparate;

  /// Name, Content
  final classes = <String, CreatedClass>{};

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
    this.unbodiedResponse = false,
    this.commentGenerator,
    NameTransformer nameTransformer,
    NameTransformer arrayTransformer,
    Map<dynamic, String> staticNameTransformer = const {},
    Map<dynamic, String> staticArrayTransformer = const {},
    this.forceObjectCounting = const [],
    this.forceToString = const [],
    this.forceSeparate = const [],
  }) : formatOutput = formatOutput ?? _formatter.format {
    var backupNameTransformer = nameTransformer ?? identitySecond;
    this.nameTransformer = (path, name) =>
        getFromStaticTransformer(staticNameTransformer, path) ??
        backupNameTransformer(path, name);

    if (combineNameTransformers) {
      this.arrayTransformer = this.nameTransformer;
    } else {
      var backupArrayTransformer =
          arrayTransformer ?? (_, name) => name + '_array';
      this.arrayTransformer = (path, name) =>
          getFromStaticTransformer(staticArrayTransformer, path) ??
          backupArrayTransformer(path, name);
    }
  }

  static String getFromStaticTransformer(
          Map<dynamic, String> map, String path) =>
      map.entries.firstWhere((element) {
        if (element.key is List) {
          return element.key.contains(path);
        } else {
          return element.key == path;
        }
      }, orElse: () => null)?.value;

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
          unbodiedResponse: settings.unbodiedResponse,
          commentGenerator: settings.commentGenerator,
          nameTransformer: settings.nameTransformer,
          arrayTransformer: settings.arrayTransformer,
          staticNameTransformer: settings.staticNameTransformer,
          staticArrayTransformer: settings.staticArrayTransformer,
          forceObjectCounting: settings.forceObjectCounting,
          forceToString: settings.forceToString,
          forceSeparate: settings.forceSeparate);

  /// Generates a wrapper for the given JSON (without imports)
  Map<String, CreatedClass> generated(Map<String, dynamic> json) {
    json = Map.unmodifiable(json);

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

    return classes;
  }

  /// Generates a single class from a map of names and types.
  CreatedClass generatedFromTypes(
      String name, String jsonPath, Map<String, ElementInfo> fields) {
    classVisitor(name, {}, jsonPath, extraFields: fields.values.toList());
    return classes.values.first;
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
    var res = StringBuffer();

    var requireHeader = false;
    var extendString = '';
    if (jsonPath == 'request') {
      extendString = 'extends BaseRequest ';
      requireHeader = true;
    } else if (jsonPath == 'response') {
      extendString = 'extends BaseResponse ';
      requireHeader = true;
    }

    res.writeln('${comment ?? ''}\nclass ${context.name} $extendString{');

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

    var hasBody = !(unbodiedResponse && context.jsonPath == 'response');

    var copyFields = [...fields];

    [
      (buffer, context, fields) =>
          fieldGenerator(buffer, context, fields, finalizeFields),
      (buffer, context, fields) =>
          constructorGenerator(buffer, context, fields, requireHeader),
      (buffer, context, fields) => getKey(buffer, context, fields, jsonType),
      (buffer, ClassContext context, fields) => fromJson(buffer, context,
          fields, forceToString, jsonType, requireHeader, hasBody),
      (buffer, context, fields) => toJson(buffer, context, fields, jsonType),
      ...extraGenerators,
    ].forEach((generator) {
      generator(res, context, fields);
      res.writeln();
    });

    res.writeln('}');

    if (!base || !(base && ignoreBase)) {
      classes[name.toLowerCase()] = CreatedClass(
          formatOutput(res.toString()),
          context,
          Map.unmodifiable(
              {for (var field in copyFields) field.dartName: field}));
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
    if (forceSeparate.contains(jsonName.toLowerCase())) {
      return true;
    }

    if (classes.containsKey(jsonName.toLowerCase()) && shareClasses) {
      return false;
    }

    return true;
  }

  /// Creates a Dart class name in PascalCase from the given JSON field name.
  /// Ignores [sharedClasses]. If [respectOverflow] is true and it would be a
  /// duplicate, it will append the incrementing number of clashes it has has.
  String createClassName(String path, String jsonName,
      {bool respectOverflow = true}) {
    var name = pascal(jsonName);
    var forceStuff = false;

    if (respectOverflow) {
      forceStuff = classes.containsKey(jsonName.toLowerCase());
    }

    if (!forceStuff) {
      forceStuff = forceSeparate.contains(jsonName.toLowerCase());
    }

    if (forceStuff) {
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
  final bool unbodiedResponse;
  final BlockCommentGenerator commentGenerator;
  final NameTransformer nameTransformer;
  final NameTransformer arrayTransformer;
  final Map<dynamic, String> staticNameTransformer;
  final Map<dynamic, String> staticArrayTransformer;
  final List<String> forceObjectCounting;
  final List<String> forceToString;
  final List<String> forceSeparate;

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
        unbodiedResponse: false,
        staticNameTransformer: const {},
        staticArrayTransformer: const {},
        forceObjectCounting: const [],
        forceToString: const [],
        forceSeparate: const [],
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
      this.unbodiedResponse,
      this.commentGenerator,
      this.nameTransformer,
      this.arrayTransformer,
      this.staticNameTransformer,
      this.staticArrayTransformer,
      this.forceObjectCounting,
      this.forceToString,
      this.forceSeparate});

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
        combineNameTransformers:
            merging.combineNameTransformers ?? fallback.combineNameTransformers,
        unbodiedResponse: merging.unbodiedResponse ?? fallback.unbodiedResponse,
        commentGenerator: merging.commentGenerator ?? fallback.commentGenerator,
        nameTransformer: merging.nameTransformer ?? fallback.nameTransformer,
        arrayTransformer: merging.arrayTransformer ?? fallback.arrayTransformer,
        staticNameTransformer:
            merging.staticNameTransformer ?? fallback.staticNameTransformer,
        staticArrayTransformer:
            merging.staticArrayTransformer ?? fallback.staticArrayTransformer,
        forceObjectCounting:
            merging.forceObjectCounting ?? fallback.forceObjectCounting,
        forceToString: merging.forceToString ?? fallback.forceToString,
        forceSeparate: merging.forceSeparate ?? fallback.forceSeparate,
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
    bool unbodiedResponse,
    BlockCommentGenerator commentGenerator,
    NameTransformer nameTransformer,
    NameTransformer arrayTransformer,
    Map<dynamic, String> staticNameTransformer,
    Map<dynamic, String> staticArrayTransformer,
    List<String> forceObjectCounting,
    List<String> forceToString,
    List<String> forceSeparate,
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
            unbodiedResponse: unbodiedResponse,
            commentGenerator: commentGenerator,
            nameTransformer: nameTransformer,
            arrayTransformer: arrayTransformer,
            staticNameTransformer: staticNameTransformer,
            staticArrayTransformer: staticArrayTransformer,
            forceObjectCounting: forceObjectCounting,
            forceToString: forceToString,
            forceSeparate: forceSeparate,
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

class CreatedClass {
  /// The lowercase name of the class
  final ClassContext context;

  /// The formatted class content
  final String content;

  /// A map of field names and its type
  final Map<String, ElementInfo> fields;

  CreatedClass(this.content, [this.context, this.fields]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreatedClass &&
          runtimeType == other.runtimeType &&
          context.name == other.context.name &&
          mapEquality.equals(fields, other.fields);

  @override
  int get hashCode => mapEquality.hash(fields) ^ context.name.hashCode;
}

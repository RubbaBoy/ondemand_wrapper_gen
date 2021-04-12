import 'package:collection/collection.dart';
import 'package:ondemand_wrapper_gen/creating.dart';
import 'package:ondemand_wrapper_gen/generator/class/generate_elements.dart';
import 'package:ondemand_wrapper_gen/generator/class/generator.dart';

const PRIMITIVES = ['int', 'double', 'bool', 'String', 'dynamic'];
const COLLECTION_PRIMITIVES = ['Map', 'List'];

var classes = <CreatedClass, int>{};

/// [noShare] is a list of jsonPaths to NOT share classes with.
/// [mergeNames] is a list of names to merge
SharedClassSeparation separateClasses(
    Map<GeneratedFile, List<SharedClass>> generationResult,
    {List<String> noShareJsonPath = const [],
    List<String> noShareNames = const [],
    List<String> mergeNames = const []}) {
  var sharedClasses = generationResult.entries
      .map((e) => e.value.toList())
      .reduce((a, b) => [...a, ...b])
      .toList();

  for (var sharedClass in sharedClasses) {
    var created = sharedClass.createdClass;
    if (!noShareJsonPath.contains(created.context.jsonPath) &&
        !noShareNames.contains(created.context.name)) {
      classes.putIfAbsent(created, () => 0);
      classes[created]++;
    }
  }

  // remove all classes with duplicate names
  classes.removeWhere((createdClass, value) {
    return classes.keys
      .where((element) => element != createdClass)
      .any((element) => element.context.name == createdClass.context.name);
  });

  classes.removeWhere((key, value) => value == 1);

  // Remove any class that contains fields that aren't primitive or also shared
  var classNames;
  var delta;
  do {
    var size = classes.length;
    classNames = classes.keys.map((e) => e.context.name).toList();
    classes.removeWhere((key, value) => !isValidClass(key, classNames));
    delta = size - classes.length;
  } while (delta != 0);

  var _sharedClasses = <SharedClass>{};
  var _mergedClasses = <SharedClass>{};

  classNames = classes.keys.map((e) => e.context.name).toList();

  // If `classes` contains a SharedClass, it's being combined
  generationResult = generationResult.map((generatedFile, gennedClasses) {
    var newClasses = <SharedClass>[];
    for (var clazz in gennedClasses) {
      var name = clazz.createdClass.context.name;

      dynamic it;
      if (mergeNames.contains(name)) {
        it = _mergedClasses;
      } else if (classNames.contains(name)) {
        it = _sharedClasses;
      } else {
        it = newClasses;
      }

      it.add(clazz);
    }
    return MapEntry(generatedFile, newClasses);
  });

  var moddedResult = generationResult
      .map((k, v) => MapEntry(k, v.map((e) => e.createdClass).toList()));

  var grouped = groupBy(
      _mergedClasses.where((sharedClass) =>
          mergeNames.contains(sharedClass.createdClass.context.name)),
          (SharedClass sharedClass) => sharedClass.createdClass.context.name);

  _sharedClasses.addAll(grouped
      .values
      .map((sharedClasses) => mergeSharedClasses(sharedClasses)));

  return SharedClassSeparation(_sharedClasses.toList(), moddedResult);
}

SharedClass mergeSharedClasses(List<SharedClass> sharedClasses) {
  var first = sharedClasses.first;
  var firstContext = first.createdClass.context;
  var newFields =
      sharedClasses.map((e) => e.createdClass.fields).reduce((a, b) => {...a, ...b});
  // TODO: Allow for settings!
  var generator = ClassGenerator(className: firstContext.name);
  return SharedClass(first.fileName, first.request, generator.generatedFromTypes(firstContext.name, firstContext.jsonPath, newFields));
}

/// Returns false if any field has the type of a non-primitive not in the
/// created class name list.
bool isValidClass(CreatedClass created, List<String> classNames) {
  var types = created.fields.values.toList();
  // Each any return true if invalid
  return !types.any((someType) => !isPrimitiveOrLocal(someType, classNames));
}

bool isPrimitiveOrLocal(ElementInfo info, List<String> classList) {
  if (!info.type.primitive) {
    if (info.type == ElementType.Array) {
      return isPrimitiveOrLocal(info.arrayInfo, classList);
    } else {
      return classList.contains(info.type.generateTypeString(info));
    }
  } else {
    return true;
  }
}

class SharedClass {
  final String fileName;
  final Request request;
  final CreatedClass createdClass;

  SharedClass(this.fileName, this.request, this.createdClass);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SharedClass &&
          runtimeType == other.runtimeType &&
          createdClass == other.createdClass;

  @override
  int get hashCode => createdClass.hashCode;
}

class SharedClassSeparation {
  /// All the classes that will be shared
  final List<SharedClass> sharedClasses;

  /// The file name and the inner classes
  final Map<GeneratedFile, List<CreatedClass>> standaloneClasses;

  SharedClassSeparation(this.sharedClasses, this.standaloneClasses);
}

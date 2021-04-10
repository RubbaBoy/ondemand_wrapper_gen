import 'package:ondemand_wrapper_gen/creating.dart';
import 'package:ondemand_wrapper_gen/generator/class/generator.dart';

const PRIMITIVES = ['int', 'double', 'bool', 'String', 'dynamic'];
const COLLECTION_PRIMITIVES = ['Map', 'List'];

var classes = <CreatedClass, int>{};

/// [noShare] is a list of jsonPaths to NOT share classes with.
SharedClassSeparation separateClasses(
    Map<GeneratedFile, List<SharedClass>> generationResult,
    {List<String> noShareJsonPath = const [],
    List<String> noShareNames = const []}) {
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

  classes.removeWhere((key, value) => value == 1);

  // remove all classes with duplicate names
  classes.removeWhere((createdClass, value) => classes.keys
      .where((element) => element != createdClass)
      .any((element) => element.context.name == createdClass.context.name));

  var classNames = classes.keys.map((e) => e.context.name).toList();
  var delta;
  do {
    var size = classes.length;
    classes.removeWhere((key, value) => !isValidClass(key, classNames));
    delta = size - classes.length;
  } while (delta != 0);

  var _sharedClasses = <SharedClass>{};

  classNames = classes.keys.map((e) => e.context.name).toList();

  // If `classes` contains a SharedClass, it's being combined
  generationResult = generationResult.map((generatedFile, gennedClasses) {
    var newClasses = <SharedClass>[];
    for (var clazz in gennedClasses) {
      dynamic it = classNames.contains(clazz.createdClass.context.name) ? _sharedClasses : newClasses;
      it.add(clazz);
    }
    return MapEntry(generatedFile, newClasses);
  });

  var moddedResult = generationResult
      .map((k, v) => MapEntry(k, v.map((e) => e.createdClass).toList()));

  return SharedClassSeparation(_sharedClasses.toList(), moddedResult);
}

/// Returns false if any field has the type of a non-primitive not in the
/// created class name list.
bool isValidClass(CreatedClass created, List<String> classNames) {
  var types = created.fields.values.toList();
  PRIMITIVES.forEach(types.remove);
  return !types.any((someType) {
    for (var prim in COLLECTION_PRIMITIVES) {
      var type = someType.replaceAll(prim, '').replaceAll(RegExp('[<>]'), '');
      if (!PRIMITIVES.contains(type)) {
        return true;
      }
    }
    return false;
  });
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

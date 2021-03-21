import 'package:ondemand_wrapper_gen/generator.dart';

import 'extensions.dart';

void fieldGenerator(
    StringBuffer buffer, ClassContext context, List<ElementInfo> fields, bool finalizeFields) {
  for (var info in fields) {
    var type = info.type;
    if (finalizeFields) {
      buffer.write('final ');
    }

    buffer.writeln(type.generate(info));
  }
}

void constructorGenerator(
    StringBuffer buffer, ClassContext context, List<ElementInfo> fields) {
  if (fields.isEmpty) {
    return;
  }

  buffer.write('${context.name}({');

  fields.forEachI((index, info) {
    if (index != 0) {
      buffer.write(', ');
    }
    buffer.write('this.${info.dartName}');
  });

  buffer.writeln('});');
}

void fromJson(
    StringBuffer buffer, ClassContext context, List<ElementInfo> fields, JsonType jsonType) {
  if (jsonType == JsonType.Object || jsonType == JsonType.KeyedObject) {

    buffer.write('${context.name}.fromJson(');

    if (jsonType == JsonType.KeyedObject) {
      var countingKey = fields.firstWhere((field) => field.countingKey, orElse: () => throw 'No counting key found in KeyedObject!');
      buffer.write('this.${countingKey.dartName}, ');
    }

    buffer.write('Map<String, dynamic> json)');

    if (fields.isEmpty) {
      buffer.writeln(';');
      return;
    }

    buffer.writeln(' :');
    fields.where((field) => !field.countingKey).forEachI((index, info) {
      if (index != 0) {
        buffer.write(',\n');
      }
      buffer.write(
          '${info.dartName} = ${info.type.generateFromJson(info).replaceAll(
              '\$', "json['${info.jsonName}']")}');
    });
    buffer.writeln(';');
  } else if (jsonType == JsonType.Array) {
    if (fields.length != 1) {
      throw 'If jsonType is Array, field length can\'t be more than 1';
    }

    var first = fields.first;
    buffer.writeln('${context.name}.fromJson(dynamic json) :');

    buffer.writeln('${first.dartName} = ${first.type.generateFromJson(first).replaceAll(
        '\$', 'json')}');

    buffer.writeln(';');
  }
}

void toJson(
    StringBuffer buffer, ClassContext context, List<ElementInfo> fields, JsonType jsonType) {
  if (jsonType == JsonType.Object || jsonType == JsonType.KeyedObject) {
    buffer.writeln('Map<String, dynamic> toJson() => {');
    fields.where((field) => !field.countingKey).forEachI((index, info) {
      if (index != 0) {
        buffer.write(',\n');
      }
      buffer.write(
          "'${info.jsonName}': ${info.type.generateToJson(info).replaceAll(
              '\$', info.dartName)}");
    });
    buffer.writeln('};');
  } else if (jsonType == JsonType.Array) {
    var first = fields.first;
    buffer.writeln('List<dynamic> toJson() => ${first.type.generateToJson(first).replaceAll(
        '\$', first.dartName)};');
  }
}

void getKey(
    StringBuffer buffer, ClassContext context, List<ElementInfo> fields, JsonType jsonType) {
  if (jsonType == JsonType.KeyedObject) {
    buffer.write('String getKey() => ');
    buffer.write(fields.firstWhere((field) => field.countingKey, orElse: () => throw 'No counting key found in KeyedObject!').dartName);
    buffer.writeln(';');
  }
}

enum JsonType {
  /// For base objects of `Map<String, dynamic>`
  Object,
  /// For objects that need to accept keys into them
  KeyedObject,
  /// For base objects of `List<Map<String, dynamic>>`
  Array
}

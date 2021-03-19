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
  if (jsonType == JsonType.Object) {
    buffer.write('${context.name}.fromJson(Map<String, dynamic> json)');

    if (fields.isEmpty) {
      buffer.writeln(';');
      return;
    }

    buffer.writeln(' :');
    fields.forEachI((index, info) {
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
  if (jsonType == JsonType.Object) {
    buffer.writeln('Map<String, dynamic> toJson() => {');
    fields.forEachI((index, info) {
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

enum JsonType {
  /// For base objects of `Map<String, dynamic>`
  Object,
  /// For base objects of `List<Map<String, dynamic>>`
  Array
}

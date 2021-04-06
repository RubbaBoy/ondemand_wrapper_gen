import 'package:ondemand_wrapper_gen/extensions.dart';
import 'package:ondemand_wrapper_gen/generator/class/generator.dart';

import 'generate_elements.dart';

void importGenerator(StringBuffer buffer) {
  buffer.writeln("import 'base.g.dart';");
  buffer.writeln();
}

void fieldGenerator(StringBuffer buffer, ClassContext context,
    List<ElementInfo> fields, bool finalizeFields) {
  for (var info in fields) {
    var type = info.type;
    buffer.writeln('  // ${info.jsonPath}');
    if (finalizeFields) {
      buffer.write('final ');
    }

    buffer.writeln(type.generate(info));
  }
}

void constructorGenerator(StringBuffer buffer, ClassContext context,
    List<ElementInfo> fields, bool requireHeader) {
  if (fields.isEmpty && !requireHeader) {
    return;
  }

  buffer.write('${context.name}({');

  [...fields.map((e) => e.dartName), if (requireHeader) null]
      .forEachI((index, name) {
    if (index != 0) {
      buffer.write(', ');
    }

    if (name == null) {
      buffer.write('HttpHeaders headers');
    } else {
      buffer.write('this.$name');
    }
  });

  buffer.write('})');

  if (requireHeader) {
    buffer.write(' : super(headers)');
  }

  buffer.write(';');
}

void fromJson(StringBuffer buffer, ClassContext context,
    List<ElementInfo> fields, JsonType jsonType, bool requireHeader, bool hasBody) {
  if (jsonType == JsonType.Object || jsonType == JsonType.KeyedObject) {
    buffer.write('${context.name}.fromJson(');

    if (jsonType == JsonType.KeyedObject) {
      var countingKey = fields.firstWhere((field) => field.countingKey,
          orElse: () => throw 'No counting key found in KeyedObject!');
      buffer.write('this.${countingKey.dartName}, ');
    }

    if (hasBody) {
      buffer.write('Map<String, dynamic> json');
    }

    if (requireHeader) {
      if (hasBody) {
        buffer.write(', ');
      }

      buffer.write('HttpHeaders headers');
    }

    buffer.write(')');

    if (fields.isEmpty && !requireHeader) {
      buffer.writeln(';');
      return;
    }

    buffer.writeln(' :');
    var nonCounting = fields.where((field) => !field.countingKey).toList();
    nonCounting.forEachI((index, info) {
      if (index != 0) {
        buffer.write(',\n');
      }
      buffer.write(
          '${info.dartName} = ${info.type.generateFromJson(info).replaceAll('\$', "json['${info.jsonName}']")}');
    });

    if (requireHeader) {
      if (nonCounting.isNotEmpty) {
        buffer.write(', ');
      }

      buffer.write('super(headers)');
    }

    buffer.writeln(';');
  } else if (jsonType == JsonType.Array) {
    // print('fields: $fields');
    if (fields.length != 1) {
      throw 'If jsonType is Array, field length can\'t be more than 1';
    }

    var first = fields.first;
    buffer.write('${context.name}.fromJson(dynamic json');

    if (requireHeader) {
      buffer.write(', HttpHeaders headers');
    }

    buffer.writeln(') :');

    buffer.writeln(
        '${first.dartName} = ${first.type.generateFromJson(first).replaceAll('\$', 'json')}');

    if (requireHeader) {
      buffer.writeln(', super(headers)');
    }

    buffer.writeln(';');
  }
}

void toJson(StringBuffer buffer, ClassContext context, List<ElementInfo> fields,
    JsonType jsonType) {
  if (jsonType == JsonType.Object || jsonType == JsonType.KeyedObject) {
    buffer.writeln('@override');
    buffer.writeln('Map<String, dynamic> toJson() => {');
    fields.where((field) => !field.countingKey).forEachI((index, info) {
      if (index != 0) {
        buffer.write(',\n');
      }
      buffer.write(
          "'${info.jsonName}': ${info.type.generateToJson(info).replaceAll('\$', info.dartName)}");
    });
    buffer.writeln('};');
  } else if (jsonType == JsonType.Array) {
    var first = fields.first;
    buffer.writeln(
        'List<dynamic> toJson() => ${first.type.generateToJson(first).replaceAll('\$', first.dartName)};');
  }
}

void getKey(StringBuffer buffer, ClassContext context, List<ElementInfo> fields,
    JsonType jsonType) {
  if (jsonType == JsonType.KeyedObject) {
    buffer.write('String getKey() => ');
    buffer.write(fields
        .firstWhere((field) => field.countingKey,
            orElse: () => throw 'No counting key found in KeyedObject!')
        .dartName);
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

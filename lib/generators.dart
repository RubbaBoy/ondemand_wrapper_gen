import 'package:ondemand_wrapper_gen/generator.dart';

import 'extensions.dart';

void fieldGenerator(StringBuffer buffer, ClassContext context, Map<String, ElementInfo> fields) {
  for (var name in fields.keys) {
    var info = fields[name];
    var type = info.type;
    buffer.writeln(type.generate(name, info));
  }
}

void constructorGenerator(
    StringBuffer buffer, ClassContext context, Map<String, ElementInfo> fields) {
  buffer.write('${context.name}(');

  fields.forEachI((index, name, info) {
    if (index != 0) {
      buffer.write(', ');
    }
    buffer.write('this.$name');
  });

  buffer.writeln(');');
}

void fromJson(
    StringBuffer buffer, ClassContext context, Map<String, ElementInfo> fields) {
  buffer.writeln('${context.name}.fromJson(Map<String, dynamic> json) :');
  fields.forEachI((index, name, info) {
    if (index != 0) {
      buffer.write(',\n');
    }
    buffer.write(info.type.generateFromJson(name, info));
  });
  buffer.writeln(';');
}

void toJson(
    StringBuffer buffer, ClassContext context, Map<String, ElementInfo> fields) {
  buffer.writeln('Map<String, dynamic> toJson() => {');
  fields.forEachI((index, name, info) {
    if (index != 0) {
      buffer.write(',\n');
    }
    buffer.write(info.type.generateToJson(name, info));
  });
  buffer.writeln('};');
}

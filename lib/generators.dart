import 'package:ondemand_wrapper_gen/generator.dart';

import 'extensions.dart';

void fieldGenerator(
    StringBuffer buffer, ClassContext context, List<ElementInfo> fields) {
  for (var info in fields) {
    var type = info.type;
    buffer.writeln(type.generate(info));
  }
}

void constructorGenerator(
    StringBuffer buffer, ClassContext context, List<ElementInfo> fields) {
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
    StringBuffer buffer, ClassContext context, List<ElementInfo> fields) {
  buffer.writeln('${context.name}.fromJson(Map<String, dynamic> json) :');
  fields.forEachI((index, info) {
    if (index != 0) {
      buffer.write(',\n');
    }
    buffer.write(
        '${info.dartName} = ${info.type.generateFromJson(info).replaceAll('\$', "json['${info.jsonName}']")}');
  });
  buffer.writeln(';');
}

void toJson(
    StringBuffer buffer, ClassContext context, List<ElementInfo> fields) {
  buffer.writeln('Map<String, dynamic> toJson() => {');
  fields.forEachI((index, info) {
    if (index != 0) {
      buffer.write(',\n');
    }
    buffer.write("'${info.jsonName}': ${info.type.generateToJson(info).replaceAll('\$', info.dartName)}");
  });
  buffer.writeln('};');
}

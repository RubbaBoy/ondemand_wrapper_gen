
import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:ondemand_wrapper_gen/creating.dart';
import 'package:ondemand_wrapper_gen/extensions.dart';
import 'package:ondemand_wrapper_gen/generator/class/generate_utils.dart';

final _formatter = DartFormatter();

class GenerateEntryFile {
  final String Function(String) formatOutput;
  final bool finalizeFields;

  GenerateEntryFile(
      {this.finalizeFields = true, String Function(String code) formatOutput})
      : formatOutput = formatOutput ?? _formatter.format;

  Future<void> generate(String name, List<CreatedRequestFile> createdFiles, List<String> constantFields, File file) =>
      file.writeAsString(generateString(name, createdFiles, constantFields));

  /// Generates an entry file, containing request methods for every request.
  /// All [constantFields] will be declared in the constructor, e.g. the overall
  /// site ID.
  String generateString(String name, List<CreatedRequestFile> createdFiles,
      List<String> constantFields) {
    var res = StringBuffer();

    generateImports(createdFiles, res);

    res.writeln('\nclass $name {');

    res.writeln('Map<String, String> baseHeaders = {};');
    res.writeln('_get_config.Response config;');
    createConstructor(name, constantFields, res);
    res.writeln();

    createdFiles.forEach((e) => createMethod(e, constantFields, res));

    res.writeln('}');
    return formatOutput(res.toString());
  }

  void generateImports(List<CreatedRequestFile> createdFiles, StringBuffer buffer) {
    buffer.writeln("import 'base.dart';");

    for (var file in createdFiles) {
      var name = file.request.name;
      buffer.writeln("import '$name.dart' as _$name;");
    }
  }

  void createConstructor(
      String name, List<String> constantFields, StringBuffer buffer) {
    for (var field in constantFields) {
      if (finalizeFields) {
        buffer.write('final ');
      }

      buffer.writeln('String $field;');
    }

    buffer.write('\n$name({');

    constantFields.forEachI((i, field) {
      if (i != 0) {
        buffer.write(', ');
      }

      buffer.write('this.$field');
    });

    buffer.writeln('});');
  }

  void createMethod(CreatedRequestFile createdFile, List<String> constantFields,
      StringBuffer buffer) {
    var request = createdFile.request;
    var name = '_${request.name}';
    buffer.write('Future<$name.Response> ${camel(name)}($name.Request request');

    var methodParams = request.placeholders
        .where((field) => !constantFields.contains(field));

    if (methodParams.isNotEmpty) {
      buffer.write(', {');
    }

    methodParams
        .forEachI((i, field) {
      if (i != 0) {
        buffer.write(', ');
      }

      buffer.write('String $field');
    });

    if (methodParams.isNotEmpty) {
      buffer.write('}');
    }

    var bodyParam = '';
    if (!createdFile.unbodiedResponse) {
      bodyParam = 'res.json(), ';
    }

    buffer.writeln(
        '''
    ) async {
    
    var res = await ${createdFile.method.toLowerCase()}('${replaceParams(request.url, request.placeholders)}', request, {...request.headers, ...baseHeaders});
    if (res.statusCode != 200) {
      return Future.error('Status \${res.statusCode}: \${res.body}');
    }
    
    return $name.Response.fromJson(${bodyParam}res.headers);
    }
        ''');
  }

  /// Replaces the given string's `$` with its respective [placeholders] value,
  /// with a leading $. For example, given a string `one/$/two/$/three` and a
  /// placeholders value of `"four", "five"`, the resulting string is
  /// `one/four/two/five/three`
  String replaceParams(String string, List<String> placeholders) {
    var index = 0;
    return string.replaceAllMapped(RegExp(r'\$'), (_) => '\$${placeholders[index++]}');
  }
}

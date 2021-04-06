import 'dart:convert';

import 'package:dart_style/dart_style.dart';
import 'package:http/http.dart' as http;
import 'package:ondemand_wrapper_gen/creating.dart';
import 'package:ondemand_wrapper_gen/extensions.dart';
import 'package:ondemand_wrapper_gen/gen/list_places.g.dart' as list_places;
import 'package:ondemand_wrapper_gen/generator.dart';

final _formatter = DartFormatter();

class GenerateEntryFile {
  final String Function(String) formatOutput;
  final bool finalizeFields;

  GenerateEntryFile(
      {this.finalizeFields = true, String Function(String code) formatOutput})
      : formatOutput = formatOutput ?? _formatter.format;

  /// Generates an entry file, containing request methods for every request.
  /// All [constantFields] will be declared in the constructor, e.g. the overall
  /// site ID.
  String generate(String name, List<CreatedFile> createdFiles,
      List<String> constantFields) {
    var res = StringBuffer();

    generateImports(createdFiles, res);

    res.writeln('\nclass $name {');

    createConstructor(name, constantFields, res);
    res.writeln();

    createdFiles.forEach((e) => createMethod(e, constantFields, res));

    res.writeln('}');
    print(res.toString());
    return formatOutput(res.toString());
  }

  void generateImports(List<CreatedFile> createdFiles, StringBuffer buffer) {
    buffer.writeln("import 'dart:convert';");
    buffer.writeln("import 'package:http/http.dart' as http;");

    for (var file in createdFiles) {
      var name = file.request.name;
      buffer.writeln("import 'package:ondemand_wrapper_gen/gen/$name.g.dart' as $name;");
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

  void createMethod(CreatedFile createdFile, List<String> constantFields,
      StringBuffer buffer) {
    var request = createdFile.request;
    var name = request.name;
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

    buffer.writeln(
        '''
    ) async {
    
    var res = await http.post(Uri.parse('${replaceParams(request.url, request.placeholders)}'));
    if (res.statusCode != 200) {
      return Future.error('Status \${res.statusCode}: \${res.body}');
    }
    
    return $name.Response.fromJson(jsonDecode(res.body));
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

class OnDemandAccess {
  final int site;

  OnDemandAccess({this.site = 1312});

  Future<list_places.Response> listPlaces(list_places.Request request,
      {String contextId, String displayId}) async {
    var res = await http.post(Uri.parse(
        'https://ondemand.rit.edu/api/sites/$site/$contextId/concepts/$displayId'));
    if (res.statusCode != 200) {
      return Future.error('Status ${res.statusCode}: ${res.body}');
    }
    return list_places.Response.fromJson(jsonDecode(res.body));
  }
}

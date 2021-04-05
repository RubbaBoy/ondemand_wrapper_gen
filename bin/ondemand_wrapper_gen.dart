import 'dart:convert';
import 'dart:io';

import 'package:ondemand_wrapper_gen/creating.dart';
import 'package:ondemand_wrapper_gen/extensions.dart';
import 'package:ondemand_wrapper_gen/generator.dart';
import 'package:ondemand_wrapper_gen/hmmm.dart';

typedef CreateGenerator = ClassGenerator Function(
    Map<String, dynamic> json, String method);

void main(List<String> arguments) {
  var input = jsonDecode(
      File('E:\\ondemand_fiddler\\ondemand-1.har').readAsStringSync());
  var log = Log.fromJson(input['log']);
  print('Comment = ${log.comment}');

  // Url, Entry
  var bruh = <String, List<Entry>>{};

  for (var entry in log.entries) {
    bruh.putIfAbsent(entry.request.url, () => []).add(entry);
  }

  bruh.forEach((key, value) {
    print('URL: $key');
    for (var value1 in value) {
      print('\t${value1.startedDateTime}');
    }
  });

  var generateDirectory = [r'E:\ondemand_wrapper_gen\lib\gen'].directory;
  generateDirectory.createSync();

  var creator = Creator();
  creator.create(generateDirectory, bruh);
}

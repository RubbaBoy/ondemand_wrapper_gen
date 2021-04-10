import 'dart:convert';

import 'package:ondemand_wrapper_gen/creating.dart';
import 'package:ondemand_wrapper_gen/extensions.dart';
import 'package:ondemand_wrapper_gen/generator/base_generator.dart';
import 'package:ondemand_wrapper_gen/generator/class/generator.dart';
import 'package:ondemand_wrapper_gen/generator/entry_file.dart';
import 'package:ondemand_wrapper_gen/generator/generate_main.dart';
import 'package:ondemand_wrapper_gen/har_api.dart';

typedef CreateGenerator = ClassGenerator Function(
    Map<String, dynamic> json, String method);

/// Arguments:
/// - The .har file path
/// - The lib directory to pipe data
Future<void> main(List<String> args) async {
  var input = jsonDecode(args[0].file.readAsStringSync());
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

  var generateDirectory = args[1].directory;
  await generateDirectory.create();

  var creator = Creator();
  var created = creator.createWrapper(generateDirectory, bruh, true);

  await GenerateEntryFile().generate('OnDemand', created.whereType<CreatedRequestFile>().toList(), ['siteNumber'], [generateDirectory, 'ondemand_requests.dart'].file);

  await BaseGenerator().generate([generateDirectory, 'base.dart'].file);

  await GenerateMain().generate(created, [generateDirectory, 'ondemand.dart'].file);
}

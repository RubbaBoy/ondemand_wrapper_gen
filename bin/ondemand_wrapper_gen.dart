import 'dart:convert';
import 'dart:io';

import 'package:ondemand_wrapper_gen/extensions.dart';
import 'package:ondemand_wrapper_gen/generator.dart';
import 'package:ondemand_wrapper_gen/hmmm.dart';
import 'package:ondemand_wrapper_gen/utility.dart';

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

  // groupEntries(bruh, (url) => )

  var allowedUrls = [
    'https://ondemand.rit.edu/api/config',
    'https://ondemand.rit.edu/api/sites/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/kiosk-items/get-items',
    'https://ondemand.rit.edu/api/sites/1312'
  ];

  for (var url in bruh.keys) {
    if (!allowedUrls.contains(url)) {
      continue;
    }

    var defaultConfig = GeneratorSettings.defaultSettings().copyWith(
        childrenRequireAggregation: true,
        forceBaseClasses: true,
        commentGenerator: defaultCommentGenerator());

    var settings = defaultConfig;

    if (url.endsWith('get-items')) {
      settings = defaultConfig.copyWith(staticNameTransformer: {
        'Response': 'FoodItem',
        'ChildGroups': 'ChildGroup',
        'ItemImages': 'ItemImage',
      }, staticArrayTransformer: {
        'Response': 'ItemList'
      }, staticArrayFieldTransformer: {
        'Response': 'items',
      }, commentGenerator: defaultCommentGenerator(['Request', 'ItemList']));
    }

    var name = snake(url.substring(url.lastIndexOf('/')));
    var outFile = [generateDirectory, '$name.g.dart'].file;
    outFile.writeAsString(generate(bruh, name, url, settings));
  }

  //
  // generate(bruh, 'getItems',
  //     'https://ondemand.rit.edu/api/sites/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/kiosk-items/get-items');

  // var entry = bruh['https://ondemand.rit.edu/api/sites/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/kiosk-items/get-items'].first;
  // var responseJson = entry.response.content.json;
  // print('responseJson = $responseJson');
  //
  // var response = get_items.Response.fromJson(responseJson);
  // print('Item: ${response.name}');
}

Map<String, List<Entry>> groupEntries(Map<String, List<Entry>> allData,
    String Function(String url) nameTransform) {
  var map = <String, List<Entry>>{};
  map.forEach((key, value) =>
      map.putIfAbsent(nameTransform(key), () => <Entry>[]).addAll(value));
  return map;
}

String generate(Map<String, List<Entry>> allData, String name, String url,
    GeneratorSettings settings) {
  var aggregated = aggregateList(allData, url);
  var method = getMethod(allData, url);
  var gen =
      ClassGenerator.fromSettings(settings.copyWith(url: url, method: method));
  return gen.generated(aggregated);
}

String getMethod(Map<String, List<Entry>> allData, String url) =>
    allData[url].first.request.method;

BlockCommentGenerator defaultCommentGenerator(
        [List<String> commentClasses = const ['Request', 'Response']]) =>
    (context) {
      if (!commentClasses.contains(context.name)) {
        return null;
      }

      return '''
  Url: ${context.url}
  Method: ${context.method}
  ''';
    };

Map<String, dynamic> aggregateList(
    Map<String, List<Entry>> allData, String url) {
  var entries = allData[url];

  return {
    'request': [for (var entry in entries) entry.request.postData.json],
    'response': [for (var entry in entries) entry.response.content.json]
  };
}

void output(List<Entry> entries, String name) {
  var out = 'E:\\ondemand_wrapper_gen\\rout\\$name';
  Directory(out).createSync(recursive: true);
  for (var i = 0; i < entries.length; i++) {
    var entry = entries[i];
    var outFile = File('$out\\$i.json');
    var request = entry.request.postData.json;
    var response = entry.response.content.json;
    outFile.writeAsStringSync(prettyEncode({
      'request': request,
      'response': response,
    }));
  }
}

void cleanRequest() {}

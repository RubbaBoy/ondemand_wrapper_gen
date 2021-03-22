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

  var allowedUrls = <dynamic>[
    // 'https://ondemand.rit.edu/api/config',
    // 'https://ondemand.rit.edu/api/sites/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/kiosk-items/get-items',
    // 'https://ondemand.rit.edu/api/sites/1312',
    // 'https://ondemand.rit.edu/static/assets/manifest.json'
    // 'https://ondemand.rit.edu/api/userProfile/decryptSamlCookie',
    // 'https://ondemand.rit.edu/api/sites/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/getKitchenLeadTimeForStores',
//     'https://ondemand.rit.edu/api/sites/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/concepts/2162',
//     'https://ondemand.rit.edu/api/sites/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/concepts/2162/menus/3403',
//     [
//       'https://ondemand.rit.edu/api/sites/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/kiosk-items/5f121d554f05a8000c1b87df',
//       'https://ondemand.rit.edu/api/sites/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/kiosk-items/5f121d554f05a8000c1b8822'
//     ],

    'https://ondemand.rit.edu/api/order/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/orders',
    // 'https://ondemand.rit.edu/api/order/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/orders/5e446350-e67d-4ec3-a348-2393ccc63691',
    // 'https://ondemand.rit.edu/api/atrium/accountInquiry',
    // 'https://ondemand.rit.edu/api/sites/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/getRevenueCategory',
    // 'https://ondemand.rit.edu/api/atrium/getAtriumTendersFromPaymentTypeList',
    // 'https://ondemand.rit.edu/api/order/getPaymentTenderInfo',
    // 'https://ondemand.rit.edu/api/atrium/authAtriumPayment',
    // 'https://ondemand.rit.edu/api/order/capacityCheck',
    // 'https://ondemand.rit.edu/api/order/createMultiPaymentClosedOrder',
    // 'https://ondemand.rit.edu/api/communication/getSMSReceipt',
    // 'https://ondemand.rit.edu/api/communication/sendSMSReceipt',
  ];

  // var entry = bruh['https://ondemand.rit.edu/api/sites/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/getKitchenLeadTimeForStores'].first;
  // var responseJson = entry.request.postData.json;
  // print('request =');
  // print(prettyEncode(responseJson));
  //
  // if (true) return;

  for (var got in allowedUrls) {
    var urls = <String>[];
    if (got is String) {
      urls = [got as String];
    } else {
      urls = got;
    }

    var defaultConfig = GeneratorSettings.defaultSettings().copyWith(
        childrenRequireAggregation: true,
        forceBaseClasses: true,
        commentGenerator: defaultCommentGenerator());

    var settings = defaultConfig;

    var firstUrl = urls.first;
    if (firstUrl.endsWith('get-items')) {
      settings = defaultConfig.copyWith(
          staticNameTransformer: {
            // 'response': 'FoodItem',
            'response.response': 'FoodItem',
            'response.response.childGroups': 'ChildGroup',
            'response.response.itemImages': 'ItemImage',
            'response.response.priceLevels': 'PriceLevel'
          },
          staticArrayTransformer: {
            'response': 'Response'
          },
          staticArrayFieldTransformer: {
            'response#response': 'items',
          },
          commentGenerator: defaultCommentGenerator(['Request', 'ItemList']),
          forceObjectCounting: ['response.response.priceLevels']);
    } else if (firstUrl.endsWith('1312')) {
      settings = defaultConfig.copyWith(staticNameTransformer: {
        'response.response.pickUpConfig.conceptEntries': 'ConceptEntry',
        'response.response.atriumConfig.tenders': 'Tender'
      }, forceObjectCounting: [
        'response.response.pickUpConfig.conceptEntries',
        'response.response.atriumConfig.tenders'
      ]);
    } else if (firstUrl.endsWith('getKitchenLeadTimeForStores')) {
      settings = defaultConfig.copyWith(staticNameTransformer: {
        'response[]': 'Kitchen',
        'request.request': 'KitchenRequest',
        'request': 'Request',
        'response#response': 'kitchens'
        // 'response'
      }, staticArrayFieldTransformer: {
        'response': 'kitchens',
        'request#request': 'kitchenRequests'
      }, forceObjectCounting: [
        'response'
      ]);
    } else if (firstUrl.contains('kiosk-items')) {
      // doesn't end with get-items
      settings = defaultConfig.copyWith(
          staticNameTransformer: {
            'response.childGroups': 'ChildGroup',
            'response.itemImages': 'ItemImage',
            'response.priceLevels[]': 'PriceLevel',
            'response.modifiers': 'Modifiers',
            'response.modifiers.modifiers': 'Modifier'
          }, forceObjectCounting: [
        'response.priceLevels',
        'response.childGroups.childItems.priceLevels'
      ]);
    }

    var name = snake(firstUrl.substring(firstUrl.lastIndexOf('/')));
    var outFile = [generateDirectory, '$name.g.dart'].file;
    outFile.writeAsString(generate(bruh, name, urls, settings));
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

String generate(Map<String, List<Entry>> allData, String name,
    List<String> urls, GeneratorSettings settings) {
  var aggregated = aggregateList(allData, urls);
  var method = getMethod(allData, urls.first);
  var gen = ClassGenerator.fromSettings(
      settings.copyWith(url: urls.first, method: method));
  // print(prettyEncode(aggregated));
  return gen.generated(aggregated);
}

String getMethod(Map<String, List<Entry>> allData, String url) =>
    allData[url].first.request.method;

BlockCommentGenerator defaultCommentGenerator(
        [List<String> detailedCommentClasses = const [
          'Request',
          'Response'
        ]]) =>
    (context) {
      var details = '';

      if (detailedCommentClasses.contains(context.name)) {
        details = '''
  Url: ${context.url}
  Method: ${context.method}
  
  ''';
      }

      return '''$details
  Json path:
  ```
  ${context.jsonPath}
  ```
  ''';
    };

Map<String, dynamic> aggregateList(
    Map<String, List<Entry>> allData, List<String> urls) {
  var entries = allData
      .where((key, value) => urls.contains(key))
      .values
      .reduce((value, element) => [...value, ...element])
      .toList();

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

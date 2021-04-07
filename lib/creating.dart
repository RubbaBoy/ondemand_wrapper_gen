import 'dart:io';

import 'package:ondemand_wrapper_gen/extensions.dart';
import 'package:ondemand_wrapper_gen/generator/class/generate_utils.dart';
import 'package:ondemand_wrapper_gen/generator/class/generator.dart';
import 'package:ondemand_wrapper_gen/har_api.dart';

class Creator {
  /// Creates classes from entries. Returns the list of files created.
  List<CreatedFile> createWrapper(Directory generateDirectory, Map<String, List<Entry>> entries, [bool write = true]) {
    final settings = GeneratorSettings.defaultSettings().copyWith(
        childrenRequireAggregation: true,
        forceBaseClasses: true,
        combineNameTransformers: true,
        commentGenerator: defaultCommentGenerator());

    var requests = [
      Request('get_config', 'https://ondemand.rit.edu/api/config'),

      // siteNumber   get_config => response#tenantId (1312)
      // contextId   get_config => response#contextId (dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd)
      // Gets items in a kitchen
      Request('get_items',
          r'https://ondemand.rit.edu/api/sites/$/$/kiosk-items/get-items',
          placeholders: [
            'siteNumber',
            'contextId'
          ],
          nameMap: {
            'response.response': 'FoodItem',
            'response.response.childGroups': 'ChildGroup',
            'response.response.itemImages': 'ItemImage',
            'response.response.priceLevels[]': 'PriceLevel',
            'response#response': 'items',
            'response': 'Response'
          },
          forceCounting: [
            'response.response.priceLevels'
          ]),

      Request('login', r'https://ondemand.rit.edu/api/login/anonymous/$', placeholders: ['siteNumber']),

      // Gets the kitchens in the site
      Request('get_kitchens', r'https://ondemand.rit.edu/api/sites/$',
          placeholders: [
            'siteNumber'
          ],
          nameMap: {
            ...multiResponse('Kitchen', 'kitchens'),
            'response.response.pickUpConfig.conceptEntries': 'ConceptEntry',
            'response.response.atriumConfig.tenders': 'Tender',
          },
          forceCounting: [
            'response.response.pickUpConfig.conceptEntries',
            'response.response.atriumConfig.tenders'
          ],
      forceToString: [
        'response.response.atriumConfig#terminalId'
      ]),

      // Gets the manifest
      Request('get_manifest',
          r'https://ondemand.rit.edu/static/assets/manifest.json'),

      // Decrypts the RIT cookie
      Request('decrypt_cookie',
          r'https://ondemand.rit.edu/api/userProfile/decryptSamlCookie'),

      // Gets kitchen lead times for the given site siteNumber
      // This is made when you click "Find food" with a time option NOT "As soon as possible".
      // The dateTime in the request is when the time slot ends, used to get random info about the lead times (NOT what is open)
      Request('get_leads',
          r'https://ondemand.rit.edu/api/sites/$/getKitchenLeadTimeForStores',
          placeholders: [
            'contextId'
          ],
          nameMap: {
            ...multiRequest('KitchenRequest', 'kitchenRequests'),
            'response[]': 'Kitchen',
            'response#response': 'kitchens',
            // 'response': 'kitchens',
          },
          forceCounting: [
            'response'
          ]),

      // displayId   get_kitchens => response.response#displayProfileId (2162)     is the store-specific DISPLAY ID. This is bound
      // to a single store, more specific requests being made with
      // its "place" id (For commons the display ID is 2162 and real ID 3403)
      Request(
          'list_places', r'https://ondemand.rit.edu/api/sites/$/$/concepts/$',
          placeholders: ['siteNumber', 'contextId', 'displayId'],
          nameMap: multiResponse('Place', 'places')),

      // placeId   list_placed => response.[].response#id (3403) is the PLACE id (see above)
      // Gets the menus for a given place (at RIT only one menu is used)
      Request('get_menus',
          r'https://ondemand.rit.edu/api/sites/$/$/concepts/$/menus/$',
          placeholders: ['siteNumber', 'contextId', 'displayId', 'placeId'],
          nameMap: multiResponse('Place', 'places')),

      // itemId   get_menus => request.[].menus.[].categories#item (5f121d554f05a8000c1b87df)   The food item ID (static/const)
      // Gets an item from a menu by its itemId
      Request(
          'get_item', r'https://ondemand.rit.edu/api/sites/$/$/kiosk-items/$',
          placeholders: [
            'siteNumber',
            'contextId',
            'itemID'
          ],
          nameMap: {
            'response.childGroups': 'ChildGroup',
            'response.itemImages': 'ItemImage',
            'response.priceLevels[]': 'PriceLevel',
            'response.modifiers': 'Modifiers',
            'response.modifiers.modifiers': 'Modifier'
          },
          forceCounting: [
            'response.priceLevels',
            'response.childGroups.childItems.priceLevels'
          ]),

      // Adds an order to your open orderId (in the request)
      // Orders are stored server-side. I'm not sure where the order number comes from, though
      // This and add_cart are the same, this just provides some more request parameters
      Request('add_cart_adv', r'https://ondemand.rit.edu/api/order/$/$/orders',
          placeholders: [
            'siteNumber',
            'contextId'
          ],
          nameMap: {
            'response.addedItem.priceLevels[]': 'PriceLevel',
            'request.item.priceLevels[]': 'PriceLevel'
          }),

      // orderId (5e446350-e67d-4ec3-a348-2393ccc63691)
      // Adds an item to the cart
      Request('add_cart', r'https://ondemand.rit.edu/api/order/$/$/orders/$',
          placeholders: [
            'siteNumber',
            'contextId',
            'orderId'
          ],
          forceCounting: [
            'response.addedItem.priceLevels',
            'request.item.priceLevels'
          ]),

      // Checks account balances for the given logged in account.
      // TODO: Explain what `request.request.data` is
      Request('account_inquiry',
          r'https://ondemand.rit.edu/api/atrium/accountInquiry',
          nameMap: {
            ...multiRequest('Inquiry', 'inquiries'),
            ...multiResponse('InquiryResponse', 'inquiries')
          }),

      // idk
      Request('get_revenue_category',
          r'https://ondemand.rit.edu/api/sites/$/$/getRevenueCategory',
          placeholders: ['siteNumber', 'contextId'],
          nameMap: multiResponse('Category', 'categories')),

      // Gets the tender verification codes for the atrium
      Request('get_tenders',
          r'https://ondemand.rit.edu/api/atrium/getAtriumTendersFromPaymentTypeList',
          nameMap: {'response#response': 'tenders', 'response[]': 'Tender'},
          forceCounting: ['response']),

      // Gets verification code IDs from a given tender ID list
      Request('get_tender_info',
          r'https://ondemand.rit.edu/api/order/getPaymentTenderInfo', nameMap: {
        'response#response': 'tenderInfos',
        'response[]': 'TenderInfo'
      }, forceCounting: [
        'response'
      ]),

      // Authorized the payment to be made
      // Uses data from account_inquiry => response.response
      Request('auth_payment',
          r'https://ondemand.rit.edu/api/atrium/authAtriumPayment',
          forceCounting: ['request.paymentTenderInfo']),

      // Ensures that the order can be placed during the selected time
      Request(
          'check_capacity', r'https://ondemand.rit.edu/api/order/capacityCheck',
          nameMap: {'request.conceptTimeFrames[]': 'ConceptTimeFrame'},
          forceCounting: ['request.conceptTimeFrames']),

      // Actually places the order
      Request('create_closed_order',
          r'https://ondemand.rit.edu/api/order/createMultiPaymentClosedOrder',
          nameMap: {'request.receiptInfo.items.priceLevels[]': 'PriceLevel'},
          forceCounting: ['request.receiptInfo.items.priceLevels']),

      // Gets the SMS text to send
      Request('get_sms',
          r'https://ondemand.rit.edu/api/communication/getSMSReceipt'),

      // Sends the confirmation text message
      Request('send_sms',
          r'https://ondemand.rit.edu/api/communication/sendSMSReceipt'),

      // Gets the estimated wait time for the given items
      Request('get_wait_time',
          r'https://ondemand.rit.edu/api/order/$/$/getWaitTimeForItems',
          placeholders: ['siteNumber', 'contextId']),
    ];

    var createdFiles = <CreatedFile>[];
    var usedUrls = <String>[];
    for (var request in requests) {
      var generator = request.getSettings(settings);
      var placeholderData = getPlaceholdered(request.url, entries.keys.toList(), usedUrls);
      var urls = placeholderData.map((e) => e.url).toList();

      var outFile = [generateDirectory, '${request.name}.g.dart'].file;

      var generatedFile = generate(entries, request.name, urls, generator);
      if (write) {
        outFile.writeAsString(generatedFile.generated);
      }

      createdFiles.add(CreatedFile(request, outFile, generatedFile.method, generatedFile.unbodiedResponse));
    }

    return createdFiles;
  }

  _GeneratedFile generate(Map<String, List<Entry>> allData, String name,
      List<String> urls, GeneratorSettings settings) {
    var aggregated = aggregateList(allData, urls);

    if (aggregated == null) {
      return null;
    }

    var method = getMethod(allData, urls.first);
    var gen = ClassGenerator.fromSettings(
        settings.copyWith(url: urls.first, method: method, unbodiedResponse: !aggregated.hasResponseBody));
    print(urls.first);
    return _GeneratedFile(gen.generated(aggregated.aggregated), method, !aggregated.hasResponseBody);
  }

  String getMethod(Map<String, List<Entry>> allData, String url) =>
      allData[url].first.request.method;

  _AggregatedResponse aggregateList(
      Map<String, List<Entry>> allData, List<String> urls) {
    var entries = allData
        .where((key, value) => urls.contains(key))
        .values
        .safeReduce((value, element) => [...value, ...element])
        ?.toList();

    if (entries == null) {
      return null;
    }

    var hasRequestBody = entries.first.request.method == 'POST';
    var hasResponseBody = entries.first.response.content.mimeType.contains('application/json');

    return _AggregatedResponse({
      'request': [for (var entry in entries) entry.request.postData.json],
      'response': [if (hasResponseBody) for (var entry in entries) entry.response.content.json else {}]
    }, hasRequestBody, hasResponseBody);
  }

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

  Map<String, String> multiRequest(String className, String fieldName) =>
      initialArray('request', className, fieldName);

  Map<String, String> multiResponse(String className, String fieldName) =>
      initialArray('response', className, fieldName);

  Map<String, String> initialArray(
          String name, String className, String fieldName) =>
      {
        name: camel(name),
        '$name.$name': className,
        '$name#$name': fieldName,
      };
}

class CreatedFile {
  final Request request;
  final File created;
  final String method;
  final bool unbodiedResponse;

  CreatedFile(this.request, this.created, this.method, this.unbodiedResponse);
}

class _GeneratedFile {
  final String generated;
  final String method;
  final bool unbodiedResponse;

  _GeneratedFile(this.generated, this.method, this.unbodiedResponse);
}

class _AggregatedResponse {
  final Map<String, dynamic> aggregated;
  final bool hasRequestBody;
  final bool hasResponseBody;

  _AggregatedResponse(this.aggregated, this.hasRequestBody, this.hasResponseBody);
}

class Request {
  /// The friendly name of the request
  final String name;

  /// The URL of the request. Any dynamic variables should be replaced with a $.
  final String url;

  /// The placeholders of the URL, in order of the inserted $'s.
  final List<String> placeholders;

  final Map<String, String> nameMap;

  final List<String> forceCounting;

  final List<String> forceToString;

  Request(this.name, this.url,
      {this.placeholders = const [], this.nameMap, this.forceCounting, this.forceToString = const []});

  /// Gets the settings with the base (or default) of [base].
  GeneratorSettings getSettings(GeneratorSettings base) => base.copyWith(
      staticNameTransformer: nameMap, forceObjectCounting: forceCounting, forceToString: forceToString);
}

/// The [placeholderUrls] is a list of placeholder URLs.
/// The [absoluteUrl] is an actual request URL
List<PlaceholderData> getPlaceholdered(
    String placeholderUrl, List<String> absoluteUrls, List<String> usedUrls) {
  var testingUrl = placeholderUrl.split('/').toList();
  return absoluteUrls
  .where((url) => !usedUrls.contains(url))
      .map((url) => PlaceholderData(url, []))
      .map((placeholderData) {
    var splitUrl = placeholderData.url.split('/');
    if (splitUrl.length != testingUrl.length) {
      return null;
    }

    for (var i = 0; i < testingUrl.length; i++) {
      var placeholder = testingUrl[i] == r'$';
      if (!placeholder && testingUrl[i] != splitUrl[i]) {
        return null;
      }

      if (placeholder) {
        placeholderData.data.add(splitUrl[i]);
      }
    }
    usedUrls.add(placeholderData.url);
    return placeholderData;
  }).toList()
        ..removeWhere((value) => value == null);
}

class PlaceholderData {
  final String url;
  final List<String> data;

  PlaceholderData(this.url, this.data);

  @override
  String toString() {
    return 'PlaceholderData{url: $url, data: $data}';
  }
}

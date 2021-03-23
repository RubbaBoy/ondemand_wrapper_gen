import 'package:meta/meta.dart';
import 'package:ondemand_wrapper_gen/generator.dart';

class Creator {

  void create() {
    final GeneratorSettings settings = null;

    var requests = [
      Request('get_config', 'https://ondemand.rit.edu/api/config'),
      // siteNumber   get_config => response#tenantId (1312)
      // contextId   get_config => response#contextId (dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd)
      // Gets items in a kitchen
      Request('get_items', r'https://ondemand.rit.edu/api/sites/$/$/kiosk-items/get-items', placeholders: ['siteNumber', 'contextId']),
      // Gets the kitchens in the site
      Request('get_kitchens', r'https://ondemand.rit.edu/api/sites/$', placeholders: ['siteNumber']),
      // Gets the manifest
      Request('get_manifest', r'https://ondemand.rit.edu/static/assets/manifest.json'),
      // Decrypts the RIT cookie
      Request('decrypt_cookie', r'https://ondemand.rit.edu/api/userProfile/decryptSamlCookie'),
      // Gets kitchen lead times for the given site siteNumber
      // This is made when you click "Find food" with a time option NOT "As soon as possible".
      // The dateTime in the request is when the time slot ends, used to get random info about the lead times (NOT what is open)
      Request('get_leads', r'https://ondemand.rit.edu/api/sites/$/getKitchenLeadTimeForStores', placeholders: ['contextId']),
      // displayId   get_kitchens => response.response#displayProfileId (2162)     is the store-specific DISPLAY ID. This is bound
      // to a single store, more specific requests being made with
      // its "place" id (For commons the display ID is 2162 and real ID 3403)
      Request('list_places', r'https://ondemand.rit.edu/api/sites/$/$/concepts/$', placeholders: ['siteNumber', 'contextId', 'displayId']),
      // placeId   list_placed => response.[].response#id (3403) is the PLACE id (see above)
      // Gets the menus for a given place (at RIT only one menu is used)
      Request('get_menus', r'https://ondemand.rit.edu/api/sites/$/$/concepts/$/menus/$', placeholders: ['siteNumber', 'contextId', 'displayId', 'placeId']),
      // itemId   get_menus => request.[].menus.[].categories#item (5f121d554f05a8000c1b87df)   The food item ID
      // Gets an item from a menu by its itemId
      Request('', r'https://ondemand.rit.edu/api/sites/$/$/kiosk-items/$', placeholders: ['siteNumber', 'contextId', 'itemID']),
      // Adds an order to your open orderId (in the request)
      // Orders are stored server-side. I'm not sure where the order number comes from, though
      Request('', r'https://ondemand.rit.edu/api/order/$/$/orders', placeholders: ['siteNumber', 'contextId']),
      // orderId (5e446350-e67d-4ec3-a348-2393ccc63691)
      Request('', r'https://ondemand.rit.edu/api/order/$/$/orders/$', placeholders: ['siteNumber', 'contextId', 'orderId']),
      // Checks account balances for the given logged in account.
      // TODO: Explain what `request.request.data` is
      Request('', r'https://ondemand.rit.edu/api/atrium/accountInquiry'),
      // idk
      Request('', r'https://ondemand.rit.edu/api/sites/$/$/getRevenueCategory', placeholders: ['siteNumber', 'contextId']),
      // Gets the tender verification codes for the atrium
      Request('', r'https://ondemand.rit.edu/api/atrium/getAtriumTendersFromPaymentTypeList'),
      // Gets verification code IDs from a given tender ID list
      Request('', r'https://ondemand.rit.edu/api/order/getPaymentTenderInfo'),
      // Authorized the payment to be made
      // Uses data from account_inquiry => response.response
      Request('', r'https://ondemand.rit.edu/api/atrium/authAtriumPayment'),
      // Ensures that the order can be placed during the selected time
      Request('', r'https://ondemand.rit.edu/api/order/capacityCheck'),
      // Actually places the order
      Request('', r'https://ondemand.rit.edu/api/order/createMultiPaymentClosedOrder'),
      // Gets the SMS text to send
      Request('', r'https://ondemand.rit.edu/api/communication/getSMSReceipt'),
      // Sends the confirmation text message
      Request('', r'https://ondemand.rit.edu/api/communication/sendSMSReceipt'),

    ];
  }
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

  Request(this.name, this.url, {this.placeholders = const [], this.nameMap, this.forceCounting});

  /// Gets the settings with the base (or default) of [base].
  GeneratorSettings getSettings(GeneratorSettings base) => base.copyWith(
      staticNameTransformer: nameMap,
      forceObjectCounting: forceCounting
  );
}
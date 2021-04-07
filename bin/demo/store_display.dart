import 'package:ondemand_wrapper_gen/gen/get_config.g.dart' as _get_config;
import 'package:ondemand_wrapper_gen/gen/get_items.g.dart' as _get_items;
import 'package:ondemand_wrapper_gen/gen/login.g.dart' as _login;
import 'package:ondemand_wrapper_gen/gen/get_kitchens.g.dart' as _get_kitchens;
import 'package:ondemand_wrapper_gen/gen/get_manifest.g.dart' as _get_manifest;
import 'package:ondemand_wrapper_gen/gen/decrypt_cookie.g.dart'
as _decrypt_cookie;
import 'package:ondemand_wrapper_gen/gen/get_leads.g.dart' as _get_leads;
import 'package:ondemand_wrapper_gen/gen/list_places.g.dart' as _list_places;
import 'package:ondemand_wrapper_gen/gen/get_menus.g.dart' as _get_menus;
import 'package:ondemand_wrapper_gen/gen/get_item.g.dart' as _get_item;
import 'package:ondemand_wrapper_gen/gen/add_cart_adv.g.dart' as _add_cart_adv;
import 'package:ondemand_wrapper_gen/gen/add_cart.g.dart' as _add_cart;
import 'package:ondemand_wrapper_gen/gen/account_inquiry.g.dart'
as _account_inquiry;
import 'package:ondemand_wrapper_gen/gen/get_revenue_category.g.dart'
as _get_revenue_category;
import 'package:ondemand_wrapper_gen/gen/get_tenders.g.dart' as _get_tenders;
import 'package:ondemand_wrapper_gen/gen/get_tender_info.g.dart'
as _get_tender_info;
import 'package:ondemand_wrapper_gen/gen/auth_payment.g.dart' as _auth_payment;
import 'package:ondemand_wrapper_gen/gen/check_capacity.g.dart'
as _check_capacity;
import 'package:ondemand_wrapper_gen/gen/create_closed_order.g.dart'
as _create_closed_order;
import 'package:ondemand_wrapper_gen/gen/get_sms.g.dart' as _get_sms;
import 'package:ondemand_wrapper_gen/gen/send_sms.g.dart' as _send_sms;
import 'package:ondemand_wrapper_gen/gen/get_wait_time.g.dart'
as _get_wait_time;

import 'init.dart';

void main(List<String> args) => StoreDisplay().main();

class StoreDisplay {
  Future<void> main() async {
    var initialization = Initialization();
    var onDemand = await initialization.createOnDemand();
    var config = initialization.config;

    var contextId = config.contextID;

    configPrint(config);

    var kitchens = await onDemand.getKitchens(_get_kitchens.Request());
    printKitchens(kitchens);

    // Click "find food"

    var commons = kitchens.kitchens
        .firstWhere((kitchen) => kitchen.name == 'The Commons');

    // No leads (we want as soon as possible)

    var places = await onDemand.listPlaces(_list_places.Request(scheduleTime:
    _list_places.ScheduleTime(startTime: '7:00 PM', endTime: '7:15 PM')),
        contextId: contextId, displayId: commons.displayProfileId);

    // Lists places in this kitchen (I think only one always??)
    var place = places.places.first;
    if (places.places.length > 1) {
      print('Contains more than 1 place!!!');
    }

    print('Place "${place.name}"');
    print('Available from ${place.availableAt.open} - ${place.availableAt.close} (Currently ${place.availableNow ? 'available' : 'unavailable'})');
    print('Menus:');
    // Menus for ??? usually only one used I think, a lot are tests
    // for (var menu in place.menus) {
      // print('Menu ${menu.name} (${menu.id})');
      // Categories such as grill, sub, pizza, etc.
      // for (var category in menu.categories) {
        // print('\tCategory ${category.name} - ${category.items.length} items');
      // }
    // }

    print('place id: ${place.id}');

    var menus = await onDemand.getMenus(_get_menus.Request(
        menus: place.menus.map((e) => _get_menus.Menus.fromJson(e.toJson())).toList(),
      scheduleTime: _get_menus.ScheduleTime(startTime: '7:00 PM', endTime: '7:15 PM'),
      schedule: place.schedule.map((e) => _get_menus.Schedule.fromJson(e.toJson())).toList(),
      scheduledDay: 0,
      storePriceLevel: PRICE_LEVEL,
      currencyUnit: CURRENCY
    ),
        contextId: contextId,
        displayId: commons.displayProfileId, placeId: place.id);

    // The menu being used today
    var mainMenu = menus.places.first;
    print('The menu being used today is "${mainMenu.name}" (${mainMenu.id})');
    print('Categories: ${mainMenu.categories.map((category) => category.name).join(', ')}');

    var grillCategory = mainMenu.categories
        .firstWhere((category) => category.name == 'Grill');

    var items = await onDemand.getItems(_get_items.Request(
      conceptId: place.id,
      itemIds: grillCategory.items,
      currencyUnit: CURRENCY,
      storePriceLevel: PRICE_LEVEL,
    ), contextId: contextId);

    print('Retrieved items:');
    for (var item in items.items) {
      print('${item.name} ${item.price.amount} ${item.price.currencyUnit}');
    }

    var hamburger = items.items.firstWhere((item) => item.name == 'Commons Hamburger');

    // If childGroups is FILLED, do get_item request (childGroups#id is the id of something idk)
    print('ChildGroups: ${hamburger.childGroups.map((e) => e.id).toList()}');

    var gotItem = await onDemand.getItem(_get_item.Request(
        storePriceLevel: PRICE_LEVEL,
        currencyUnit: CURRENCY,
    ), contextId: contextId, itemID: hamburger.id);

    print('Select options for ${gotItem.name}:');

    print('Child groups!');
    for (var child in gotItem.childGroups) {
      print('${child.name} - min: ${child.minimum} max: ${child.maximum} type: ${child.groupType}');
      for (var option in child.childItems) {
        print('\t${option.displayText}');
      }
    }
  }

  void printKitchens(_get_kitchens.Response response) {
    print('${response.kitchens.length} kitchens found:\n');
    for (var kitchen in response.kitchens) {
      print('${kitchen.name}\t${kitchen.availableAt.opens} - ${kitchen.availableAt.closes}');
    }
  }

  void configPrint(_get_config.Response config) {
    print('Using config tenant #${config.tenantID}:');
    print('Contains ${config.storeList.length} stores:');
    for (var value in config.storeList) {
      print('\tStore "${value.storeInfo.storeName}"');
    }
  }
}

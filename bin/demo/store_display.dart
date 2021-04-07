import 'init.dart';
import 'dart:io';
import 'package:ondemand_wrapper_gen/gen/ondemand.g.dart';
import 'package:ondemand_wrapper_gen/gen/get_config.g.dart' as _get_config;
import 'package:ondemand_wrapper_gen/gen/get_items.g.dart' as _get_items;
import 'package:ondemand_wrapper_gen/gen/login.g.dart' as login;
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
  }

  void printKitchens(_get_kitchens.Response response) {
    print('${response.kitchens.length} kitchens found:\n');
    for (var kitchen in response.kitchens) {
      print('${kitchen.name}');
      print('\tOpens: ${kitchen.availableAt.opens}');
      print('\tCloses: ${kitchen.availableAt.closes}');
      // TODO: kitchenContextId: kitchen.kitchenSettings.kitchenContextId
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

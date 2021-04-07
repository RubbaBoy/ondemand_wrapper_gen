import 'package:ondemand_wrapper_gen/gen/ondemand.g.dart';
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

import '../init.dart';
import 'package:ondemand_wrapper_gen/extensions.dart';

import 'time_handler.dart';

class OnDemandLogic {
  OnDemand onDemand;
  _get_config.Response config;
  _get_kitchens.Response _kitchens;

  Future<void> init() async {
    var initialization = Initialization();
    onDemand = await initialization.createOnDemand();
    config = initialization.config;
  }

  Future<_get_kitchens.Response> _getKitchens() async =>
      _kitchens ??= await onDemand.getKitchens(_get_kitchens.Request());

  Future<List<OrderTime>> getOrderTimes() async {
    Time minTime;
    Time maxTime;
    for (var kitchen in (await _getKitchens()).kitchens) {
      var opens = Time.fromString(kitchen.availableAt.opens);
      var closes = Time.fromString(kitchen.availableAt.closes);

      minTime ??= opens;
      maxTime ??= closes;

      if (isAfter(opens, minTime)) {
        minTime = opens;
      }

      if (isAfter(maxTime, closes)) {
        maxTime = closes;
      }
    }

    var scheduledOrdering = config.properties.scheduledOrdering;
    return calculateOrderTimes(minTime, maxTime, scheduledOrdering.intervalTime, scheduledOrdering.bufferTime);
  }

  Future<List<_get_kitchens.Kitchen>> getKitchens() async =>
      (await _getKitchens()).kitchens;
}

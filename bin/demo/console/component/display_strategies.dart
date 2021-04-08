import 'package:dart_console/dart_console.dart';

import '../ansi.dart';
import 'base.dart';
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

class DefaultDisplay<T> with OptionStringStrategy<T> {
  const DefaultDisplay();

  @override
  String displayString(Option<T> option) => option.display();
}

/// Displays kitchens in the format of:
/// ```
/// name
/// open - close
/// ```
/// For example:
/// ```
/// The Commons
/// 7:00 am - 10:00 pm
/// ```
class KitchenDisplay with OptionStringStrategy<_get_kitchens.Kitchen> {
  const KitchenDisplay();

  @override
  String displayString(Option<_get_kitchens.Kitchen> option) {
    var value = option.value;
    var res = '${value.name}\n\n';
    res += ansiSetColor(ansiForegroundColors[ConsoleColor.brightBlack]);
    res += '${value.availableAt.opens} - ${value.availableAt.closes}';
    res += ansiResetColor;
    return res;
  }
}

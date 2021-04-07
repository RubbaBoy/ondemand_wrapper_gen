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

Map<String, String> env = Platform.environment;

final UID = env['UID'];

final SITE_NUMBER = '1312';

class Initialization {

  OnDemand onDemand;
  _get_config.Response config;

  Future<OnDemand> createOnDemand() async {
    onDemand = OnDemand(siteNumber: SITE_NUMBER);

    await _login();
    print('hereeee');
    config = await _getConfig();
    print('config = $config');

    return onDemand;
  }

  Future<void> _login() async {
    var loggedIn = await onDemand.login(login.Request());
    var accessToken = loggedIn.headers['access-token'];
    onDemand.baseHeaders = {
      'access-token': accessToken,
      'authorization': accessToken,
    };
  }

  Future<_get_config.Response> _getConfig() async =>
      await onDemand.getConfig(_get_config.Request());
}

class TenderIds {
  static const TIGER_BUCKS = '9';
  static const DINING_DOLLARS = '16';

  static const TIGER_BUCKS_DATA = '1';
  static const DINING_DOLLARS_DATA = '4';

  static const TENDERS = <String, String>{
    TIGER_BUCKS: 'Tiger Bucks',
    DINING_DOLLARS: 'Dining Dollars'
  };
}

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

class OnDemandLogic {
  OnDemand onDemand;
  _get_config.Response config;
  _get_kitchens.Response getKitchens;

  Future<void> init() async {
    var initialization = Initialization();
    onDemand = await initialization.createOnDemand();
    config = initialization.config;


  }

  Future<List<OrderTime>> getOrderTimes() async {
    Time minTime;
    Time maxTime;
    // TODO: This doesn't seem right to get the times
    getKitchens ??= await onDemand.getKitchens(_get_kitchens.Request());
    for (var kitchen in getKitchens.kitchens) {
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
    return _getOrderTimes(minTime, maxTime, scheduledOrdering.intervalTime, scheduledOrdering.bufferTime);
  }

  List<OrderTime> _getOrderTimes(Time startTime, Time endTime, int intervalTime, int bufferTime) {
    var times = <OrderTime>[];
    while (isAfter(startTime, endTime)) {
      var newStartTime = startTime.add(minute: intervalTime);
      times.add(OrderTime(startTime, newStartTime));
      startTime = newStartTime;
    }

    var now = Time.fromDateTime(DateTime.now().add(Duration(minutes: bufferTime)));
    while (times.isNotEmpty && isAfter(times.first.start, now)) {
      times.removeAt(0);
    }

    return times;
  }
}

/// Checks if the time b is after a.
/// Time examples: `7:30 pm`, `12:45 am`
bool isAfter(Time a, Time b) {
  if (a == b) {
    return false;
  }

  var aHour = a.hour;
  var bHour = b.hour;
  if (a.amPm == 'pm') {
    aHour = a.hour + 12;
  }

  if (b.amPm == 'pm') {
    bHour = b.hour + 12;
  }

  if (bHour > aHour) {
    return true;
  } else if (bHour < aHour) {
    return false;
  }

  return b.minute > a.minute;
}

/// And order time (time should be in increments of 15 minutes)
class OrderTime {
  final Time start;
  final Time end;

  const OrderTime(this.start, this.end);

  @override
  String toString() => '$start - $end';
}

class Time {
  final int hour;
  final int minute;
  final String amPm;

  Time(this.hour, this.minute, this.amPm);

  factory Time.fromString(String time) {
    var split = time.split(RegExp(r'[\s:]'));
    return Time(split[0].parseInt(), split[1].parseInt(), split[2]);
  }

  Time.fromDateTime(DateTime dateTime)
    : hour = (dateTime.hour % 12),
      minute = dateTime.minute,
      amPm = dateTime.hour > 12 ? 'pm' : 'am';

  Time copy({int hour, int minute, String amPm}) =>
      Time(hour ?? this.hour, minute ?? this.minute, amPm ?? this.amPm);

  Time add({int hour = 0, int minute = 0}) {
    var newHour = this.hour + hour;
    var newMinute = this.minute + minute;
    var newAmPm = amPm;

    newHour += (newMinute / 60).floor();
    newMinute %= 60;

    var excessHour = (newHour / 12).floor();
    newHour %= 12;

    if (excessHour % 2 != 0) {
      newAmPm = amPm == 'am' ? 'pm' : 'am';
    }

    return Time(newHour, newMinute, newAmPm);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Time &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute &&
          amPm == other.amPm;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode ^ amPm.hashCode;

  @override
  String toString() {
    var printHour = hour;
    if (hour == 0) {
      printHour = 12;
    }
    return '$printHour:${minute.toString().padLeft(2, '0')} $amPm';
  }
}

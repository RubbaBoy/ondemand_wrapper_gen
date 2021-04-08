import 'package:ondemand_wrapper_gen/extensions.dart';

void main(List<String> args) {
  print(calculateOrderTimes(Time.fromString('1:09 am'), Time.fromString('9:15 pm'), 15, 0));
}

List<OrderTime> calculateOrderTimes(Time startTime, Time endTime, int intervalTime, int bufferTime) {
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
import 'console/logic.dart';
import 'console/time_handler.dart';

class OrderPlaceTime {
  static const ASAP = OrderPlaceTime('As soon as possible');
  static const FIND = OrderPlaceTime('Find a time');

  static const List<OrderPlaceTime> values = [ASAP, FIND];

  final String display;

  /// If this isn't an ASAP order, the time
  final OrderTime time;

  const OrderPlaceTime(this.display, [this.time]);

  const OrderPlaceTime.fromTime(this.time)
      : display = null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderPlaceTime &&
          ((display != null && display == other.display) ||
              (display == null && time == other.time));

  @override
  int get hashCode => display.hashCode ^ time.hashCode;

  @override
  String toString() => display ?? '$time';
}

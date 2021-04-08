import 'package:dart_console/dart_console.dart';
import 'package:ondemand_wrapper_gen/gen/get_kitchens.g.dart' as _get_kitchens;

import '../../enums.dart';
import '../ansi.dart';
import '../time_handler.dart';
import 'base.dart';

class DefaultOptionManager<T> with OptionManager<T> {
  const DefaultOptionManager();

  @override
  bool isSelectable(T _) => true;
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
class KitchenOptionManager with OptionManager<KitchenSelector> {
  const KitchenOptionManager();

  @override
  List<FormattedString> displayFormattedString(Option<KitchenSelector> option) {
    var kitchen = option.value.kitchen;
    return [
      FormattedString(kitchen.name),
      FormattedString(
          '${kitchen.availableAt.opens} -\n${kitchen.availableAt.closes}',
          ansiSetColor(ansiForegroundColors[ConsoleColor.brightBlack])),
      if (!option.selectable)
        FormattedString('Closed',
            ansiSetColor(ansiForegroundColors[ConsoleColor.brightRed]))
    ];
  }

  @override
  bool isSelectable(KitchenSelector selector) {
    var time = selector.time;
    var kitchen = selector.kitchen;
    if (time == OrderPlaceTime.ASAP) {
      return !kitchen.isAsapOrderDisabled &&
          kitchen.availableAt.availableNow;
    }

    return kitchen.isScheduleOrderEnabled &&
            isBetweenOrderTime(time.time.start, OrderTime.fromAvailableAt(kitchen.availableAt));
  }
}

class KitchenSelector {
  final _get_kitchens.Kitchen kitchen;
  final OrderPlaceTime time;

  KitchenSelector(this.kitchen, this.time);
}

class BruhOptionManager with OptionManager<Bruh> {
  const BruhOptionManager();

  @override
  List<FormattedString> displayFormattedString(Option<Bruh> bruh) =>
      <FormattedString>[
        FormattedString('The Commons'),
        FormattedString('11:00 am -\n9:00 pm',
            ansiSetColor(ansiForegroundColors[ConsoleColor.brightBlack])),
      ];

  @override
  bool isSelectable(Bruh t) => true;
}

class Bruh {}

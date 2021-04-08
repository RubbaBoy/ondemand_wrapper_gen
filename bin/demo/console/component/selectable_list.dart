import 'package:dart_console/dart_console.dart';
import 'package:meta/meta.dart';
import '../console_util.dart';
import 'dart:math' as math;

import '../../console.dart';
import 'base.dart';
import 'display_strategies.dart';

class SelectableList<T> {

  final Coordinate position;

  final int width;

  /// Will enable scrolling after the given amount of lines (or until the end
  /// of the screen is reached)
  final int scrollAfter;

  /// If [true], this will act as a checkbox. If [false], it will act as a
  /// radio.
  final bool multi;

  /// The minimum amount of items that may be selected.
  final int min;

  /// The maximum amount of items that may be selected
  final int max;

  /// If the first item should be automatically selected
  final bool autoSelect;

  /// The items being displayed. [toString()] is invoked on [T] to display
  /// in the console.
  final List<Option<T>> items;

  /// The prompt that is shown at the top
  final String upperDescription;

  /// The prompt that is shown at the bottom
  final String lowerDescription;

  /// The [Console] object.
  final Console console;

  final OptionStringStrategy<T> stringStrategy;

  /// The list index the cursor is at
  int index = 0;

  /// The active cursor position, used for resetting.
  Coordinate _cursor;

  /// If scrolling is used
  bool scrolling;

  /// The top index
  int scrollFrom = 0;

  /// The bottom index
  int scrollTo = 0;

  SelectableList({@required this.console, this.position, this.width, int scrollAfter, @required List<T> items, this.lowerDescription, this.upperDescription, this.multi = true, this.min = 0, this.max = 1, this.autoSelect = false, this.stringStrategy = const DefaultDisplay()})
      : items = items.map((item) => Option(item)).toList(),
        scrollAfter = scrollAfter ?? double.maxFinite.toInt() {
    if (autoSelect) {
      this.items.first.selected = true;
    }

    scrolling = items.length > this.scrollAfter;
    scrollTo = math.min(items.length, this.scrollAfter);
  }

  /// Same as [#display(void Function(List<T>))] but only takes the first
  /// element from the callback (or null).
  void displayOne(void Function(T) callback) =>
      display((list) => callback(list.isEmpty ? null : list.first));

  /// Displays the list, and when everything is selected, [callback] is invoked
  /// once.
  void display(void Function(List<T> selected) callback) {
    _redisplay();

    /// 0 is no wrapping occurred
    /// 1 if a wrap to 0 occurred
    /// -1 is a wrapped to `length - 1` occurred
    int processIndex() {
      if (index > items.length - 1) {
        index = 0;
        return 1;
      } else if (index < 0) {
        index = items.length - 1;
        return -1;
      }
      return 0;
    }

    /// Returns if a wrap occurred
    bool processWrapIndex() {
      var wrap = processIndex();

      var diff = scrollTo - scrollFrom;
      if (wrap == 1) {
        scrollFrom = 0;
        scrollTo = diff;
        return true;
      } else if (wrap == -1) {
        scrollTo = items.length;
        scrollFrom = scrollTo - diff;
        return true;
      }

      return false;
    }

    Key key;
    while ((key = console.readKey()) != null) {
      if (key.controlChar == ControlCharacter.arrowUp) {
        index--;
        if (!processWrapIndex() && scrolling && index + 1== scrollFrom) {
          scrollFrom--;
          scrollTo--;
        }
      } else if (key.controlChar == ControlCharacter.arrowDown) {
        index++;
        if (!processWrapIndex() && scrolling && index == scrollTo) {
          scrollFrom++;
          scrollTo++;
        }
      } else if (key.char == ' ') {
        if (multi) {
          if (items[index].selected) {
            items[index].selected = false;
          } else if (amountSelected() < max) {
            items[index].selected = true;
          }
        } else {
          var selected = getSelected();
          if (selected.isNotEmpty) {
            selected.first.selected = false;
          }

          items[index].selected = true;
        }
      } else if (key.controlChar == ControlCharacter.enter) {
        var selected = getSelected().length;
        if (selected >= min && selected <= max) {
          break;
        }
      } else if (key.controlChar == ControlCharacter.ctrlC) {
        close(console, 'Terminal closed by user');
      }

      _redisplay();
    }

    clearView(console, _cursor, width, _cursor.row - position.row + 1);
    callback(getSelected().map((option) => option.value).toList());
  }

  int amountSelected() => getSelected().length;

  List<Option<T>> getSelected() =>
      items.where((option) => option.selected).toList();

  void _redisplay() {
    console.cursorPosition = position;

    var upperLines = printText(upperDescription, false);

    var row = 0;
    for (var i = scrollFrom; i < scrollTo; i++) {
      var value = items[i];
      console.setForegroundColor(ConsoleColor.brightBlack);
      console.write('[');
      console.setForegroundColor(value.selected ? ConsoleColor.brightGreen : ConsoleColor.red);
      console.write(index == i ? '-' : 'x');
      console.setForegroundColor(ConsoleColor.brightBlack);
      console.write('] ');
      console.resetColorAttributes();

      var wrapped = wrapString(value.display(), width, 4);
      console.write(wrapped);
      console.writeLine();

      row += wrapped.split('\n').length;
    }

    var lowerLines = printText(lowerDescription, true);

    _cursor = position.add(row: row + upperLines + lowerLines, col: lowerDescription?.length ?? 0);
  }

  /// Prints test, returning a list of the used newlines;
  int printText(String test, bool newlineBefore) {
    var descriptionLines = 0;
    if (test != null) {
      var printingDesc = wrapString(test, width);
      if (newlineBefore) {
        console.writeLine();
      }

      console.writeLine(printingDesc);

      if (!newlineBefore) {
        console.writeLine();
      }

      descriptionLines = printingDesc.split('\n').length;
    }
    return descriptionLines;
  }
}

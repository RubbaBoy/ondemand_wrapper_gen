import 'package:dart_console/dart_console.dart';
import 'package:meta/meta.dart';
import 'console_util.dart';

import '../console.dart';

class SelectableList<T> {

  final Coordinate position;

  final int width;

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

  /// The list index the cursor is at
  int index = 0;

  /// The active cursor position, used for resetting.
  Coordinate _cursor;

  SelectableList({@required this.console, this.position, this.width, @required List<T> items, this.lowerDescription, this.upperDescription, this.multi = true, this.min = 0, this.max = 1, this.autoSelect = false})
      : items = items.map((item) => Option(item)).toList() {
    if (autoSelect) {
      this.items.first.selected = true;
    }
  }

  /// Same as [#display(void Function(List<T>))] but only takes the first
  /// element from the callback (or null).
  void displayOne(void Function(T) callback) =>
      display((list) => callback(list.isEmpty ? null : list.first));

  /// Displays the list, and when everything is selected, [callback] is invoked
  /// once.
  void display(void Function(List<T> selected) callback) {
    _redisplay();

    Key key;
    while ((key = console.readKey()) != null) {
      if (key.controlChar == ControlCharacter.arrowUp) {
        index--;
      } else if (key.controlChar == ControlCharacter.arrowDown) {
        index++;
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

      if (index > items.length - 1) {
        index = 0;
      } else if (index < 0) {
        index = items.length - 1;
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
    for (var i = 0; i < items.length; i++) {
      var value = items[i];
      console.setForegroundColor(ConsoleColor.brightBlack);
      console.write('[');
      console.setForegroundColor(value.selected ? ConsoleColor.brightGreen : ConsoleColor.red);
      console.write(index == i ? '-' : 'x');
      console.setForegroundColor(ConsoleColor.brightBlack);
      console.write('] ');
      console.resetColorAttributes();

      var wrapped = wrapString('$value', width, 4);
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

class Option<T> {
  final T value;
  bool selected;

  Option(this.value, [this.selected = false]);

  @override
  String toString() {
    // If it's an enum, return the enum name
    var split = value.toString().split('.');
    if (split.length > 1 && split[0] == value.runtimeType.toString()) {
      return split[1];
    }
    return '$value';
  }
}
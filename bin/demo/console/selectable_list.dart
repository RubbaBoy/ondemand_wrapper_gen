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

  /// The items being displayed. [toString()] is invoked on [T] to display
  /// in the console.
  final List<Option<T>> items;

  /// The prompt that is shown at the bottom
  final String description;

  /// The [Console] object.
  final Console console;

  /// The list index the cursor is at
  int index = 0;

  /// The active cursor position, used for resetting.
  Coordinate _cursor;

  SelectableList({@required this.console, this.position, this.width, @required List<T> items, this.description = 'Select the options (use arrow keys to navigate, space to select. enter to finalize)', this.multi = true, this.min = 0, this.max = 1})
      : items = items.map((item) => Option(item)).toList();

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
        return;
      }

      if (index > items.length - 1) {
        index = 0;
      } else if (index < 0) {
        index = items.length - 1;
      }

      _redisplay();
    }

    clearView();
    callback(getSelected().map((option) => option.value).toList());
  }

  /// Clears the view and resets the cursor to [position]
  void clearView() {
    var bottomLeft = _cursor.copy(col: 0);
    console.cursorPosition = bottomLeft;
    for (var i = 0; i < _cursor.row - position.row; i++) {
      console.write(' ' * width);
      console.cursorPosition = bottomLeft = bottomLeft.sub(row: 1);
    }
  }

  int amountSelected() => getSelected().length;

  List<Option<T>> getSelected() =>
      items.where((option) => option.selected).toList();

  void _redisplay() {
    console.cursorPosition = position;

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

      var wrapped = wrapString('$value', 4, width);
      console.write(wrapped);
      console.writeLine();

      row += wrapped.split('\n').length;
    }

    var printingDesc = wrapString(description, 0, width);
    console.writeLine();
    console.writeLine(printingDesc);

    _cursor = position.add(row: row + 1 + printingDesc.split('\n').length, col: description.length);
  }
}

class Option<T> {
  final T value;
  bool selected;

  Option(this.value, [this.selected = false]);

  @override
  String toString() => '$value';
}
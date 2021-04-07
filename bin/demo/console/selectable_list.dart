import 'package:dart_console/dart_console.dart';
import 'package:meta/meta.dart';

import '../console.dart';

class SelectableList<T> {

  final Coordinate position;

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

  SelectableList({@required this.console, this.position, @required List<T> items, this.description = 'Select the options (use arrow keys to navigate, space to select. enter to finalize)', this.multi = true, this.min = 0, this.max = 1})
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

    callback(getSelected().map((option) => option.value).toList());
  }

  int amountSelected() => getSelected().length;

  List<Option<T>> getSelected() =>
      items.where((option) => option.selected).toList();

  void _redisplay() {
    console.cursorPosition = position;

    for (var i = 0; i < items.length; i++) {
      var value = items[i];
      console.setForegroundColor(ConsoleColor.brightBlack);
      console.write('[');
      console.setForegroundColor(value.selected ? ConsoleColor.brightGreen : ConsoleColor.red);
      console.write(index == i ? '-' : 'x');
      console.setForegroundColor(ConsoleColor.brightBlack);
      console.write('] ');
      console.resetColorAttributes();

      console.write('$value');
      console.writeLine();
    }

    console.writeLine();
    console.writeLine(description);
  }
}

class Option<T> {
  final T value;
  bool selected;

  Option(this.value, [this.selected = false]);

  @override
  String toString() => '$value';
}
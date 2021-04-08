import 'dart:math';

import 'package:dart_console/dart_console.dart';
import 'package:ondemand_wrapper_gen/extensions.dart';
import '../console_util.dart';

import '../../console.dart';
import 'base.dart';
import 'option_managers.dart';
import 'selectable_list.dart';

final TL_CORNER = '+';
final TR_CORNER = '+';
final BR_CORNER = '+';
final BL_CORNER = '+';

final HORI_EDGE = '-';
final VERT_EDGE = '|';

class TiledSelection<T> {
  final Console console;

  final Coordinate position;

  final List<Option<T>> items;

  final int containerWidth;

  final int tileWidth;

  final int tileHeight;

  final ConsoleColor borderColor;

  final ConsoleColor selectedColor;

  final OptionManager<T> optionManager;

  int index = 0;

  int tileXCount;

  int tileYCount;

  /// The amount of tiles in the last row
  int lastTileXCount;

  /// The active cursor position, used for resetting.
  Coordinate _cursor;

  TiledSelection._(this.console, this.position, this.items, this.optionManager, this.containerWidth, this.tileWidth, this.tileHeight, this.borderColor, this.selectedColor);

  /// [tileWidth] and [tileHeight] are the outer sizes.
  /// If [autoSize] is true, [width] and [height] are unused.
  /// If [tileHeight] is too small for anything (including a space above and
  /// below text), ALL [tileHeight]s are adjusted.
  factory TiledSelection({Console console, Coordinate position, List<T> items, OptionManager<T> optionManager, int containerWidth, int tileWidth, int tileHeight, ConsoleColor borderColor, ConsoleColor selectedColor}) {
    var _items = items.map(optionManager.createOption).toList();
    _items.first.selected = true;
    return TiledSelection._(console, position, _items, optionManager, containerWidth, tileWidth, tileHeight, borderColor, selectedColor);
  }

  void show(void Function(T) callback) {
    _redisplay();

    Key key;
    // coords of the tile
    var x = index % tileXCount;
    var y = (index / tileXCount).floor();
    while ((key = console.readKey()) != null) {
      if (key.controlChar == ControlCharacter.arrowUp) {
        y--;
      } else if (key.controlChar == ControlCharacter.arrowDown) {
        y++;
      } else if (key.controlChar == ControlCharacter.arrowRight) {
        x++;
      } else if (key.controlChar == ControlCharacter.arrowLeft) {
        x--;
      } else if (key.controlChar == ControlCharacter.enter) {
        clearView(console, _cursor, containerWidth, _cursor.row - position.row);
        console.cursorPosition = position;
        callback(getSelected().first.value);
        break;
      } else if (key.controlChar == ControlCharacter.ctrlC) {
        close(console, 'Terminal closed by user');
      }

      if (x >= tileXCount) {
        x = 0;
        y--;
      } else if (y + 1 == tileYCount && x == lastTileXCount) {
        x = 0;
        y = 0;
      }

      if (x < 0) {
        if (y == 0) {
          x = lastTileXCount - 1;
          y = tileYCount - 1;
        } else {
          x = tileXCount - 1;
          y++;
        }
      }

      if (y >= tileYCount) {
        y = 0;
      }

      if (y < 0) {
        y = tileYCount - 1;
      }

      if (y == tileYCount - 1) {
        if (x > lastTileXCount - 1) {
          x = lastTileXCount - 1;
        }
      }

      var _index = (y * tileXCount) + x;
      if (_index < items.length) {
        getSelected().first.selected = false;
        items[index = _index].selected = true;
      }

      _redisplay();
    }
  }

  void _redisplay() {
    var row = position.row;
    var col = position.col;
    var _tileXCount = 0;
    var _tileYCount = 1;
    var _lastTileXCount = 0;
    var biggestHeight = 0;
    var firstRow = true;
    for (var item in items) {
      var size = drawTile(item, col, row);
      col += tileWidth + 2;
      biggestHeight = max(biggestHeight, size[1]);

      if (firstRow) {
        _tileXCount++;
      }

      _lastTileXCount++;

      if (col + tileWidth + 2 > containerWidth) {
        col = position.col;
        row += biggestHeight + 1;
        biggestHeight = 0;
        firstRow = false;
        _tileYCount++;
        _lastTileXCount = 0;
      }
    }

    tileXCount = _tileXCount;
    tileYCount = _tileYCount;
    lastTileXCount = _lastTileXCount;

    _cursor = position.copy(row: row + biggestHeight);
  }

  /// Draws a tile with the top left position being at ([x], [y])
  /// Returns the width and height size created.
  List<int> drawTile(Option<T> option, int x, int y) {
    var color = option.selected ? selectedColor : borderColor;

    var tileWidth = this.tileWidth - 2;
    var tileHeight = this.tileHeight - 2;
    console.cursorPosition = Coordinate(y++, x);

    console.setForegroundColor(color);
    console.write(TL_CORNER);
    console.write(HORI_EDGE * tileWidth);
    console.write(TR_CORNER);

    var formattedLines = wrapFormattedStringList(optionManager.displayFormattedString(option), tileWidth);

    int topSpace;
    int bottomSpace;
    if (formattedLines.length > tileHeight) {
      topSpace = 1;
      bottomSpace = 1;
    } else {
      var available = tileHeight - formattedLines.length;
      topSpace = ((available) / 2).floor();
      bottomSpace = available - topSpace;
    }

    void handleSpace(int amount) {
      for (; amount > 0; amount--) {
        console.cursorPosition = Coordinate(y++, x);
        console.write(VERT_EDGE);
        console.write(' ' * tileWidth);
        console.write(VERT_EDGE);
      }
    }

    handleSpace(topSpace);

    for (var formattedLine in formattedLines) {
      var line = formattedLine.value;
      var possibleSpaces = tileWidth - line.length; // 12
      var leftSpace = (possibleSpaces / 2).floor(); // 6
      var rightSpace = possibleSpaces - leftSpace; // 6

      console.cursorPosition = Coordinate(y++, x);

      console.setForegroundColor(color);
      console.write(VERT_EDGE);
      console.write(' ' * leftSpace);

      console.resetColorAttributes();
      if (formattedLine.asciiFormatting != null) {
        console.write(formattedLine.asciiFormatting);
      }

      console.write(line);

      console.setForegroundColor(color);
      console.write(' ' * rightSpace);
      console.write(VERT_EDGE);
    }

    handleSpace(bottomSpace);

    console.cursorPosition = Coordinate(y++, x);
    console.write(BL_CORNER);
    console.write(HORI_EDGE * tileWidth);
    console.write(BR_CORNER);
    console.resetColorAttributes();

    return [tileWidth, topSpace + bottomSpace + formattedLines.length + 2];
  }

  List<Option<T>> getSelected() =>
      items.where((option) => option.selected).toList();
}

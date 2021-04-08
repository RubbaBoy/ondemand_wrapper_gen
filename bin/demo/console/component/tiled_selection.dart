import 'dart:math';

import 'package:dart_console/dart_console.dart';

import '../../console.dart';
import 'base.dart';
import 'display_strategies.dart';
import 'selectable_list.dart';

// final TL_CORNER = String.fromCharCode(201);
// final TR_CORNER = String.fromCharCode(187);
// final BR_CORNER = String.fromCharCode(188);
// final BL_CORNER = String.fromCharCode(200);
//
// final HORI_EDGE = String.fromCharCode(205);
// final VERT_EDGE = String.fromCharCode(186);

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

  final int containerHeight;

  final int tileWidth;

  final int tileHeight;

  final ConsoleColor borderColor;

  final ConsoleColor textColor;

  final OptionStringStrategy<T> stringStrategy;

  /// [tileWidth] and [tileHeight] are the outer sizes.
  /// If [autoSize] is true, [width] and [height] are unused.
  /// If [tileHeight] is too small for anything (including a space above and
  /// below text), ALL [tileHeight]s are adjusted.
  TiledSelection({this.console, this.position, List<T> items, this.stringStrategy = const DefaultDisplay(), this.containerWidth, this.containerHeight, this.tileWidth, this.tileHeight, this.borderColor, this.textColor})
    : items = items.map((item) => Option(item)).toList();

  void show(void Function(T) callback) {
    var row = position.row;
    var col = position.col;
    var biggestHeight = 0;
    for (var item in items) {
      var size = drawTile(item, col, row);
      col += tileWidth + 2;
      biggestHeight = max(biggestHeight, size[1]);

      if (col + tileWidth + 2 > containerWidth) {
        col = position.col;
        row += biggestHeight + 1;
        biggestHeight = 0;
      }
    }
  }

  /// Draws a tile with the top left position being at ([x], [y])
  /// Returns the width and height size created.
  List<int> drawTile(Option<T> option, int x, int y) {
    var tileWidth = this.tileWidth - 2;
    var tileHeight = this.tileHeight - 2;
    console.cursorPosition = Coordinate(y++, x);

    console.setForegroundColor(borderColor);
    console.write(TL_CORNER);
    console.write(HORI_EDGE * tileWidth);
    console.write(TR_CORNER);

    var formattedLines = wrapFormattedStringList(stringStrategy.displayFormattedString(option), tileWidth);

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

      console.setForegroundColor(borderColor);
      console.write(VERT_EDGE);
      console.write(' ' * leftSpace);

      console.resetColorAttributes();
      if (formattedLine.asciiFormatting != null) {
        console.write(formattedLine.asciiFormatting);
      }

      console.write(line);

      console.setForegroundColor(borderColor);
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
}

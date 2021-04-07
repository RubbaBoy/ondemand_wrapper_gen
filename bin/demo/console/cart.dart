import 'dart:math';

import 'package:dart_console/dart_console.dart';
import 'console_util.dart';

import '../console.dart';

class Cart {
  final Console console;
  final List<Item> items;

  /// The title of the cart. By default, "Shopping Cart".
  final String title;

  /// The top-left x position. By default, 3/4 from the left of the screen.
  int x;

  /// The top-left y position. By default, [startContent].
  int y;

  /// The width. By default, 1/4 of the screen.
  int width;

  Cart._(this.console, this.items, this.title, this.x, this.y, this.width);

  factory Cart(Console console, List<Item> items,
      {String title = 'Shopping Cart', int x, int y, int width}) {
    var windowWidth = console.windowWidth;
    width ??= min(30, (windowWidth * 0.25).floor());
    x ??= windowWidth - width;
    y ??= OnDemandConsole.startContent.row;
    return Cart._(console, items, title, x, y, width);
  }

  void showCart() {
    var startCartPos = Coordinate(y, x);
    console.cursorPosition = startCartPos;
    var title = 'Shopping Cart';
    var spacing = ((width - title.length) / 2).floor();
    console.cursorPosition = startCartPos.add(col: spacing);
    console.write(title);

    console.cursorPosition = startCartPos = startCartPos.add(row: 1);

    for (var item in items) {
      console.write(item.item);
      var cost = '\$${money.format(item.price)}';
      console.cursorPosition = startCartPos.add(col: width - cost.length);
      console.write(cost);
      console.cursorPosition = startCartPos = startCartPos.add(row: 1);
    }

    console.write('Total');
    var cost =
        '\$${money.format(totalPrice())}';
    console.cursorPosition = startCartPos.add(col: width - cost.length);
    console.write(cost);
  }

  double totalPrice() {
    if (items.isEmpty) {
      return 0;
    }

    return items.map((item) => item.price).reduce((a, b) => a + b);
  }
}

class Item {
  final String item;
  final double price;

  Item(this.item, this.price);
}
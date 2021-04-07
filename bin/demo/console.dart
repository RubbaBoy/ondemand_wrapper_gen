import 'dart:async';
import 'dart:math';

import 'package:dart_console/dart_console.dart';
import 'package:intl/intl.dart';
import 'package:ondemand_wrapper_gen/extensions.dart';

import 'console/console_util.dart';
import 'console/selectable_list.dart';

final money = NumberFormat('#,##0.00', 'en_US');
final startContent = Coordinate(5, 0);

void main() {
  final console = Console();
  var height = console.windowHeight;
  var width = console.windowWidth;

  console.clearScreen();
  console.setForegroundColor(ConsoleColor.brightRed);
  console.writeLine('RIT OnDemand Terminal', TextAlignment.center);
  console.setForegroundColor(ConsoleColor.white);
  console.writeLine('by Adam Yarris', TextAlignment.center);
  console.resetColorAttributes();

  console.writeLine();

  var loading = Loading(console, Coordinate(3, (width / 2).floor() - 10), 20);
  // loading.start();

  console.cursorPosition = Coordinate(height - 2, 1);
  console.write('(c) 2021 Adam Yarris');

  var size = '${width}x$height';
  console.cursorPosition = Coordinate(height - 2, width - size.length);
  console.write(size);

  console.cursorPosition = startContent;

  var cart = Cart(console, [
    Item('Foo', 1.23),
    Item('Bar', 23.12),
    Item('Ham', 0.75),
    Item('Cheese', 1.56)
  ]);
  cart.showCart();

  console.cursorPosition = startContent;

  var breadcrumb = Breadcrumb(
      console: console,
      position: startContent.sub(row: 2),
      resetPosition: startContent,
      trail: ['one', 'two', 'three', 'four']);
  breadcrumb.update();

  var list = SelectableList<String>(
    console: console,
    position: startContent,
    items: ['one', 'two', 'three', 'four', 'five'],
    min: 1,
    max: 3,
    multi: true,
  );

  list.display((selected) {
    print('Selected: $selected');
  });
}

class Breadcrumb {
  final Console console;

  final Coordinate position;

  /// Resets the position to this after updates
  final Coordinate resetPosition;

  final ConsoleColor textColor;

  final ConsoleColor arrowColor;

  final List<String> trail;

  Breadcrumb(
      {this.console,
      this.position,
      this.resetPosition,
      this.textColor = ConsoleColor.brightGreen,
      this.arrowColor = ConsoleColor.brightRed,
      this.trail});

  void update() {
    console.cursorPosition = position;

    trail.forEachI((i, item) {
      if (i != 0) {
        console.setForegroundColor(arrowColor);
        console.write(' > ');
      }
      console.setForegroundColor(textColor);
      console.write(item);
    });

    console.cursorPosition = resetPosition;
  }
}

class Loading {
  final Console console;

  final Coordinate position;

  final int width;

  final ConsoleColor color1;

  final ConsoleColor color2;

  bool active = false;

  Timer _timer;

  int stage = 0;

  Loading(this.console, this.position, this.width,
      {this.color1 = ConsoleColor.brightRed,
      this.color2 = ConsoleColor.brightGreen});

  void start() {
    if (active) {
      return;
    }

    var adding = 1;
    active = true;
    _timer ??= Timer.periodic(Duration(milliseconds: 100), (timer) {
      var left = '█' * stage;
      var moving = '██';
      var right = '█' * (width - stage);
      console.cursorPosition = position;
      console.setForegroundColor(color1);
      console.write(left);
      console.setForegroundColor(color2);
      console.write(moving);
      console.setForegroundColor(color1);
      console.write(right);

      stage += adding;
      if (stage >= width || stage <= 0) {
        adding *= -1;
      }
    });
  }

  Coordinate stop() {
    _timer.cancel();
    active = true;
  }
}

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
    y ??= startContent.row;
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
        '\$${money.format(items.map((item) => item.price).reduce((a, b) => a + b))}';
    console.cursorPosition = startCartPos.add(col: width - cost.length);
    console.write(cost);
  }
}

class Item {
  final String item;
  final double price;

  Item(this.item, this.price);
}

String truncateString(String text, int length) =>
    length < text.length ? text.substring(0, length) : text;

void cursorDown(Console console, int amount) {
  for (var i = 0; i < amount; i++) {
    console.cursorDown();
  }
}

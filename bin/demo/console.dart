import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:dart_console/dart_console.dart';
import 'package:intl/intl.dart';
import 'package:ondemand_wrapper_gen/extensions.dart';
import 'package:ondemand_wrapper_gen/gen/ondemand.g.dart';

import 'console/breadcrumb.dart';
import 'console/cart.dart';
import 'console/console_util.dart';
import 'console/loading.dart';
import 'console/logic.dart';
import 'console/selectable_list.dart';
import 'enums.dart';

import 'init.dart';

final money = NumberFormat('#,##0.00', 'en_US');

void main() {
  OnDemandConsole().show();
}

class OnDemandConsole {

  Loading loading;

  static const startContent = Coordinate(5, 0);

  final OnDemandLogic logic = OnDemandLogic();

  final Console console = Console();

  int mainPanelWidth;

  Future<void> show() async {
    var height = console.windowHeight;
    var width = console.windowWidth;

    console.clearScreen();
    console.setForegroundColor(ConsoleColor.brightRed);
    console.writeLine('RIT OnDemand Terminal', TextAlignment.center);
    console.setForegroundColor(ConsoleColor.white);
    console.writeLine('by Adam Yarris', TextAlignment.center);
    console.resetColorAttributes();

    console.writeLine();

    loading = Loading(console, Coordinate(3, (width / 2).floor() - 10), 20);

    console.cursorPosition = Coordinate(height - 2, 1);
    console.write('(c) 2021 Adam Yarris');

    var size = '${width}x$height';
    console.cursorPosition = Coordinate(height - 2, width - size.length);
    console.write(size);

    console.cursorPosition = startContent;

    var cart = Cart(console, []);
    cart.showCart();

    console.cursorPosition = startContent;

    var breadcrumb = Breadcrumb(
        console: console,
        position: startContent.sub(row: 2),
        resetPosition: startContent,
        trail: []);
    breadcrumb.update();

    mainPanelWidth = max(width - cart.width, (width * 0.75).floor()) - 5;

    // var list = SelectableList<String>(
    //   console: console,
    //   position: startContent,
    //   width: (width / 2).floor(),
    //   items: ['one', 'two', 'three', 'four', 'five'],
    //   min: 1,
    //   max: 3,
    //   multi: true,
    // );
    //
    // list.display((selected) {
    //   console.writeLine('Selected: $selected');
    // });

    await submitTask(init());

    breadcrumb.trailAdd('Welcome');

    var time = await showWelcome();
    console.cursorPosition = startContent;

    console.writeLine('Selected time: $time');

    close(console);
  }

  Future<void> init() async {
    await logic.init();
  }

  Future<OrderPlaceTime> showWelcome() {
    final completer = Completer<OrderPlaceTime>();
    console.cursorPosition = startContent;

    var lines = writeLines(
'''Welcome to the RIT OnDemand Terminal! The goal of this is to fully utilize the RIT OnDemand through the familiarity of your terminal.
To select menu items, use arrow keys to navigate, space to select, and enter to finalize.''', mainPanelWidth);

    var timePosition = startContent.add(row: lines + 1);

    var list = SelectableList<OrderPlaceTime>(
      console: console,
      upperDescription: 'Please select a time for your order:',
      position: timePosition,
      width: mainPanelWidth,
      items: OrderPlaceTime.values,
      multi: false,
      autoSelect: true
    );

    list.displayOne((time) async {
      console.cursorPosition = timePosition;

      if (time == OrderPlaceTime.FIND) {
        time = await showTimes(timePosition);
      }

      clearView(console, timePosition, mainPanelWidth, lines + 1);
      console.cursorPosition = timePosition;

      completer.complete(time);
    });

    return completer.future;
  }

  Future<OrderPlaceTime> showTimes(Coordinate position) async {
    final completer = Completer<OrderTime>();
    var times = await submitTask(logic.getOrderTimes());

    var list = SelectableList<OrderTime>(
        console: console,
        position: position,
        upperDescription: 'Please select a time for your order:',
        width: mainPanelWidth,
        items: times,
        multi: false,
        autoSelect: true
    );

    list.displayOne(completer.complete);

    return completer.future.then((time) => OrderPlaceTime.fromTime(time));
  }

  Future<T> submitTask<T>(Future<T> future) {
    loading.start();
    return future.then((value) {
      loading.stop();
      console.resetColorAttributes();
      console.cursorPosition = startContent;
      return value;
    });
  }

  /// Writes lines wrapped to the given width, returning the newlines used.
  int writeLines(String text, int width) {
    var lines = 0;
    for (var line in text.split('\n')) {
      var wrapped = wrapString(line, width);
      lines += wrapped.split('\n').length;
      console.writeLine(wrapped);
    }
    return lines;
  }
}

String wrapString(String string, int width, [int prefixChars = 0]) {
  if (string.length + prefixChars <= width) {
    return string;
  }

  var done = <String>[];
  while (string.length + prefixChars > width) {
    var end = min(string.length - prefixChars, width - prefixChars);
    done.add(string.substring(0, end));
    string = string.substring(end);
  }
  done.add(string);

  return '${done.first.trim()}\n${done.skip(1).map((line) => '${' ' * prefixChars}${line.trim()}').join('\n')}';
}

String truncateString(String text, int length) =>
    length < text.length ? text.substring(0, length) : text;

void cursorDown(Console console, int amount) {
  for (var i = 0; i < amount; i++) {
    console.cursorDown();
  }
}

/// Clears the view and resets the cursor to [position]. [height] is inclusive.
void clearView(Console console, Coordinate bottom, int width, int height) {
  var bottomLeft = bottom.copy(col: 0);
  console.cursorPosition = bottomLeft;
  for (var i = 0; i <= height; i++) {
    console.write(' ' * width);
    console.cursorPosition = bottomLeft = bottomLeft.sub(row: 1);
  }
}

void close(Console console, [String message]) {
  if (message != null) {
    console.clearScreen();
    console.write(message);
  }
  console.resetCursorPosition();
  console.rawMode = false;
  exit(1);
}

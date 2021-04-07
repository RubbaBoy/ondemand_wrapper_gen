import 'dart:async';

import 'package:dart_console/dart_console.dart';

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
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
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

  void stop() {
    _timer.cancel();
    console.cursorPosition = position;
    console.write(' ' * (width + 2));
    active = false;
  }
}
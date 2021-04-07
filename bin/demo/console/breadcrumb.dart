import 'package:dart_console/dart_console.dart';
import 'package:ondemand_wrapper_gen/extensions.dart';

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
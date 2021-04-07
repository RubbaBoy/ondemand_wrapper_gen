import 'package:dart_console/dart_console.dart';

extension CoordinateExtension on Coordinate {
  Coordinate copy() => Coordinate(row, col);

  Coordinate add({int row = 0, int col = 0}) => Coordinate(this.row + row, this.col + col);

  Coordinate sub({int row = 0, int col = 0}) => Coordinate(this.row - row, this.col - col);
}

import 'package:dart_console/dart_console.dart';

extension CoordinateExtension on Coordinate {
  Coordinate copy({int row, int col}) => Coordinate(row ?? this.row, col ?? this.col);

  Coordinate add({int row = 0, int col = 0}) => Coordinate(this.row + row, this.col + col);

  Coordinate sub({int row = 0, int col = 0}) => Coordinate(this.row - row, this.col - col);
}

extension StringUtils on String {
  /// Splits the string by the civen pattern up to [limit] times.
  List<String> splitLimit(Pattern split, int limit) {
    var out = <String>[];
    int index;
    var start = 0;
    while (limit-- > 0 && (index = indexOf(split, start)) != -1) {
      out.add(substring(start, index));
      start = index + 1;
    }
    out.add(substring(start));
    return out;
  }
}

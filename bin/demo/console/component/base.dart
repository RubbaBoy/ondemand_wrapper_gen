class Option<T> {
  final T value;
  bool selected;

  Option(this.value, {this.selected = false});

  String display() {
    // If it's an enum, return the enum name
    var split = value.toString().split('.');
    if (split.length > 1 && split[0] == value.runtimeType.toString()) {
      return split[1];
    }
    return '$value';
  }

  @override
  String toString() {
    return 'Option{value: $value, selected: $selected}';
  }
}

/// A strategy to change the default [Option#display] method.
abstract class OptionStringStrategy<T> {
  /// Creates a display string to display the object
  String displayString(Option<T> option);
}

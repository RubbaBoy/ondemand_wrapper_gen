class Option<T> {
  final T value;
  bool selected;
  bool selectable;

  Option(this.value, {this.selectable = true, this.selected = false});

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
abstract class OptionManager<T> {

  /// Creates a display string to display the object
  String displayString(Option<T> option) => null;

  /// Invoked internally, is the actual method to use.
  List<FormattedString> displayFormattedString(Option<T> option) =>
      [FormattedString(displayString(option))];

  /// Gets if the [T] should create a selectable option.
  bool isSelectable(T t);

  Option<T> createOption(T t) => Option<T>(t, selectable: isSelectable(t));
}

class FormattedString {
  final String asciiFormatting;
  final String value;

  FormattedString(this.value, [this.asciiFormatting]);

  @override
  String toString() {
    return 'FormattedString{asciiFormatting: $asciiFormatting, value: $value}';
  }
}

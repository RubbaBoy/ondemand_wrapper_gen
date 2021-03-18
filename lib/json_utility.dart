import 'dart:convert';

final encoder = JsonEncoder.withIndent('  ');

String prettyEncode(dynamic data) => encoder.convert(data);

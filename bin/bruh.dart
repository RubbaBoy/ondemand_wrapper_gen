import 'dart:convert';

import 'package:ondemand_wrapper_gen/generator.dart';

void main(List<String> args) {
  var input = '''
{
    "something": "here",
    "integerr": 12,
    "doub": 1.234,
    "arr": ["one", "two", "three"],
    "arr_ints": [1, 2, 3],
    "arr_doubs": [1.11, 2.22, 3.33],
    "outer": {
        "inner-one": "lol",
        "inner-too": "anotha"
    },
    "bruh": ["str", 1],
    "othger": [],
    "lasdt": [
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
    ],
    "outer2": [
        {
            "huh": "bruh",
            "huh22": "bruh22"
        }
    ],
    "more": [
        [
            {"ok": "and"},
            {"bruh": "moment"}
        ]
    ]
}
    ''';

  input = '''
{
    "responses": [
        [
            {"id": "id", "name":  "name"}
        ],
        [
            {"id": "id1", "name":  "name1"},
            {"id": "id2", "name":  "name2"}
        ],
        [
            {"id": "id3", "name":  "name3"},
            {"id": "id4", "name":  "name4"},
            {"id": "id5", "name":  "name5"}
        ]
    ],
    "otherrrrr": [
        [
            {"i2d": "id", "name":  "name"}
        ],
        [
            {"i2d": "id1", "name":  "name1"},
            {"i2d": "id2", "name":  "name2"}
        ],
        [
            {"i2d": "id3", "name":  "name3"},
            {"i2d": "id4", "name":  "name4"},
            {"i2d": "id5", "name":  "name5"}
        ]
    ]
}
    ''';

  var json = jsonDecode(input);

  print('before: $json');
  // print('one: ${jsonEncode(aggregateMultiple(json))}');
  // print('after: ${aggregate(json)}');

  // var ondemandInput = jsonDecode(File('E:\\ondemand_fiddler\\ondemand-1.har').readAsStringSync());

  var gen = ClassGenerator(className: 'base', childrenRequireAggregation: true, json: json);
  print(gen.generated());
  // var gen = ClassGenerator(className: 'base', json: ondemandInput);
  // var outFile = File(r'E:\ondemand_wrapper_gen\lib\gen.g.dart');
  // outFile.writeAsString(gen.generated());
}

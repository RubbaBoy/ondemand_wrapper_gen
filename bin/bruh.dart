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
    "more": [
        [
            {"ok": "and"},
            {"bruh": "moment"}
        ]
    ]
}
    ''';

    var gen = ClassGenerator(className: 'claz', json: jsonDecode(input));
    print(gen.generated());
}

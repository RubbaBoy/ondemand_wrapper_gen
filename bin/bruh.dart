import 'dart:convert';

import 'package:ondemand_wrapper_gen/generator.dart';
import 'package:ondemand_wrapper_gen/gen/test.g.dart' as test;

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
    ],
    "shit": {
      "1": {
        "name": "foo",
        "bruh": "moment"
      },
      "2": {
        "name": "bar"
      }
    }
}
    ''';

  var json = jsonDecode(input);

  // var shit = json['shit'] as Map<String, dynamic>;

  // shit.keys.map((key) => ShitObj.fromJson(key, shit[key]));

  // print('one: ${jsonEncode(aggregateMultiple(json))}');
  // print('after: ${aggregate(json)}');

  // var ondemandInput = jsonDecode(File('E:\\ondemand_fiddler\\ondemand-1.har').readAsStringSync());

  // List<Bruh> list;

  // Map.fromIterables(list.map((e) => e.key), list.map((e) => e.toJson()));

  var gen = ClassGenerator.fromSettings(GeneratorSettings.defaultSettings().copyWith(
      childrenRequireAggregation: false,
      forceBaseClasses: false,
    forceObjectCounting: ['shit']
  ));
  print(gen.generated(json));
  // var gen = ClassGenerator(className: 'base', json: ondemandInput);
  // var outFile = File(r'E:\ondemand_wrapper_gen\lib\gen.g.dart');
  // outFile.writeAsString(gen.generated());

  // var tttt = man.keys.map((e) {
  //   print('e = $e j = ${json[e]}');
  //   return test.ShitNum.fromJson(e, json[e]);
  // }).toList();

  // print('ttt = $tttt');

  var base = test.BaseClass.fromJson(json);
  var shit = base.shit;
  for (var t in shit.shit) {
    print('${t.key}: name: ${t.name} bruh: ${t.bruh}');
  }

  print('\nJSON:${jsonEncode(shit.toJson())}');
}

class Outer {
  String innerOne;
  String innerToo;

  Outer({this.innerOne, this.innerToo});

  Outer.fromJson(Map<String, dynamic> json)
      : innerOne = json['inner-one'],
        innerToo = json['inner-too'];

  Map<String, dynamic> toJson() =>
      {'inner-one': innerOne, 'inner-too': innerToo};
}

class Outer2 {
  String huh;
  String huh22;

  Outer2({this.huh, this.huh22});

  Outer2.fromJson(Map<String, dynamic> json)
      : huh = json['huh'],
        huh22 = json['huh22'];

  Map<String, dynamic> toJson() => {'huh': huh, 'huh22': huh22};
}

class More {
  String ok;
  String bruh;

  More({this.ok, this.bruh});

  More.fromJson(Map<String, dynamic> json)
      : ok = json['ok'],
        bruh = json['bruh'];

  Map<String, dynamic> toJson() => {'ok': ok, 'bruh': bruh};
}

class Claz {
  String something;
  int integerr;
  double doub;
  List<String> arr;
  List<int> arrInts;
  List<double> arrDoubs;
  Outer outer;
  List<dynamic> bruh;
  List<Null> othger;
  List<List<int>> lasdt;
  List<Outer2> outer2;
  List<List<More>> more;

  Claz(
      {this.something,
      this.integerr,
      this.doub,
      this.arr,
      this.arrInts,
      this.arrDoubs,
      this.outer,
      this.bruh,
      this.othger,
      this.lasdt,
      this.outer2,
      this.more});

  Claz.fromJson(Map<String, dynamic> json)
      : something = json['something'],
        integerr = json['integerr'],
        doub = json['doub'],
        arr = json['arr'].cast<String>(),
        arrInts = json['arr_ints'].cast<int>(),
        arrDoubs = json['arr_doubs'].cast<double>(),
        outer = Outer.fromJson(json['outer']),
        bruh = json['bruh'],
        othger = json['othger'],
        lasdt = (json['lasdt'] as List)
            .map((e) => (e as List).cast<int>())
            .toList(),
        outer2 =
            (json['outer2'] as List).map((e) => Outer2.fromJson(e)).toList(),
        more = (json['more'] as List)
            .map((e) => (e as List).map((e1) => More.fromJson(e1)).toList())
            .toList();

  Map<String, dynamic> toJson() => {
        'something': something,
        'integerr': integerr,
        'doub': doub,
        'arr': arr,
        'arr_ints': arrInts,
        'arr_doubs': arrDoubs,
        'outer': outer.toJson(),
        'bruh': bruh,
        'othger': othger,
        'lasdt': lasdt,
        'outer2': outer2.map((e) => e.toJson()).toList(),
        'more': more.map((e) => e.map((e) => e.toJson()).toList()).toList()
      };
}
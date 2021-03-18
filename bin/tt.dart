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
      this.more});

  Claz.fromJson(Map<String, dynamic> json)
      : something = json['something'],
        integerr = json['integerr'],
        doub = json['doub'],
        arr = json['arr'],
        arrInts = json['arr_ints'],
        arrDoubs = json['arr_doubs'],
        outer = json['outer'],
        bruh = json['bruh'],
        othger = json['othger'],
        lasdt = json['lasdt'],
        more = json['more'];

  Map<String, dynamic> toJson() => {
        'something': something,
        'integerr': integerr,
        'doub': doub,
        'arr': arr,
        'arr_ints': arrInts,
        'arr_doubs': arrDoubs,
        'outer': outer,
        'bruh': bruh,
        'othger': othger,
        'lasdt': lasdt,
        'more': more
      };
}


Process finished with exit code 0

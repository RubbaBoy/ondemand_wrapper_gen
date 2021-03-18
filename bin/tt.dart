class Claz {
    String something;
    int integerr;
    double doub;
    List<String> arr;
    List<int> arr_ints;
    List<double> arr_doubs;
    dynamic outer;
    List<dynamic> bruh;
    List<Null> othger;
    List<List<int>> lasdt;
    List<List<dynamic>> more;

    Claz(
        this.something,
        this.integerr,
        this.doub,
        this.arr,
        this.arr_ints,
        this.arr_doubs,
        this.outer,
        this.bruh,
        this.othger,
        this.lasdt,
        this.more);

    Claz.fromJson(Map<String, dynamic> json)
        : something = json['something'],
            integerr = json['integerr'],
            doub = json['doub'],
            arr = json['arr'],
            arr_ints = json['arr_ints'],
            arr_doubs = json['arr_doubs'],
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
        'arr_ints': arr_ints,
        'arr_doubs': arr_doubs,
        'outer': outer,
        'bruh': bruh,
        'othger': othger,
        'lasdt': lasdt,
        'more': more
    };
}
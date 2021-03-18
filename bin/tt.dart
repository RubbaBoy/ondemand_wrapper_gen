void main(List<String> args) {
    List bruh = <dynamic>['bruh', 'two'];
    Type tp = List;

    print(tp);

  print(bruh.runtimeType == tp);
    print('${bruh.runtimeType.hashCode} == ${tp.hashCode}');
  print(bruh.runtimeType.hashCode == tp.hashCode);
  print(bruh is List);
}
/// The request/response base class, returning a static class
class BaseGenerator {
  String generate() => '''
abstract class BaseRequest {
  final List<Header> headers;

  BaseRequest(this.headers);
}

abstract class BaseResponse {
  final List<Header> headers;

  BaseResponse(this.headers);
}

class Header {
  final String name;
  final String value;

  Header(this.name, this.value);

  static List<Header> fromMap(Map<String, String> headers) =>
      headers.entries.map((e) => Header(e.key, e.value)).toList();
}
  ''';
}
/// The request/response base class, returning a static class
class BaseGenerator {
  String generate() => r'''
import 'dart:convert';
import 'dart:io';

export 'dart:io';

abstract class BaseRequest {
  Map<String, String> headers;

  BaseRequest(this.headers);

  dynamic toJson();
}

abstract class BaseResponse {
  Map<String, String> headers;

  BaseResponse(this.headers);

  dynamic toJson();
}

final httpClient = HttpClient()..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

Future<HttpClientResponse> get(String url, BaseRequest baseRequest, Map<String, String> headers) async =>
    await _startRequest('GET', url, headers);

Future<HttpClientResponse> put(String url, BaseRequest baseRequest, Map<String, String> headers) async =>
    await _startRequest('PUT', url, headers);

Future<HttpClientResponse> post(String url, BaseRequest baseRequest, Map<String, String> headers) async =>
    await _startRequest('POST', url, headers, baseRequest.toJson());

Future<HttpClientResponse> _startRequest(
    String method, String url, Map<String, String> headers,
    [dynamic body]) async {
  var request = await httpClient.openUrl(method, Uri.parse(url));
  headers?.forEach(request.headers.set);

  if (body != null) {
    request.add(utf8.encode(jsonEncode(body)));
  }

  return request.close();
}

extension BodyUtil on HttpClientResponse {
  /// Transforms the body into a decoded dynamic JSON object.
  Future<dynamic> json() async => jsonDecode(await text());
  
  /// Gets the body as text.
  Future<String> text() async => await transform(utf8.decoder).join();
}

extension HeaderUtil on HttpHeaders {
  /// Transforms the current [HttpHeaders] object into a map of the name and
  /// first header with the name.
  Map<String, String> toMap() {
    var map = <String, String>{};
    forEach((name, values) => map[name] = values.first);
    return map;
  }
}

  ''';
}

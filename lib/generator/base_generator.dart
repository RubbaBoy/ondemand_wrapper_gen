/// The request/response base class, returning a static class
class BaseGenerator {
  String generate() => r'''
import 'dart:convert';
import 'dart:io';

export 'dart:io';

abstract class BaseRequest {
  final HttpHeaders headers;

  BaseRequest(this.headers);

  dynamic toJson();
}

abstract class BaseResponse {
  final HttpHeaders headers;

  BaseResponse(this.headers);

  dynamic toJson();
}

final httpClient = HttpClient()..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

Future<HttpClientResponse> get(String url, BaseRequest baseRequest) async {
  var request = await _startRequest('GET', url, baseRequest.headers);
  return await request.close();
}

Future<HttpClientResponse> put(String url, BaseRequest baseRequest) async {
  var request = await _startRequest('PUT', url, baseRequest.headers);
  return await request.close();
}

Future<HttpClientResponse> post(String url, BaseRequest baseRequest) async {
  var request = await _startRequest('POST', url, baseRequest.headers, baseRequest.toJson());
  request.add(utf8.encode(baseRequest.toJson()));
  return await request.close();
}

Future<HttpClientRequest> _startRequest(String method, String url, HttpHeaders headers,
    [dynamic body]) async {
  var request = await httpClient.openUrl(method, Uri.parse(url));
  headers?.forEach(request.headers.set);

  if (body != null) {
    request.add(utf8.encode(jsonEncode(body)));
  }

  return request;
}

extension BodyUtil on HttpClientResponse {
  /// Transforms the body into a decoded dynamic JSON object.
  Future<dynamic> json() async => jsonDecode(await text());
  
  /// Gets the body as text.
  Future<String> text() async => await transform(utf8.decoder).join();
}

  ''';
}

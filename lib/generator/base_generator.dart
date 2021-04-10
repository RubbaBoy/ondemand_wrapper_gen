import 'dart:io';

/// The request/response base class, returning a static class
class BaseGenerator {

  Future<void> generate(File file) => file.writeAsString(generateString());

  String generateString() => r'''
import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;

export 'shared_classes.dart';
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

final httpClient = HttpClient()
  ..badCertificateCallback =
      ((X509Certificate cert, String host, int port) => true);
final ioClient = IOClient(httpClient);

Future<http.Response> get(
        String url, BaseRequest baseRequest, Map<String, String> headers) =>
    ioClient.get(Uri.parse(url), headers: headers);

Future<http.Response> put(
        String url, BaseRequest baseRequest, Map<String, String> headers) =>
    ioClient.put(Uri.parse(url), headers: headers);

Future<http.Response> post(
        String url, BaseRequest baseRequest, Map<String, String> headers) =>
    ioClient.post(Uri.parse(url),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode(baseRequest.toJson()));

extension BodyUtil on http.Response {
  /// Transforms the body into a decoded dynamic JSON object.
  dynamic json() => jsonDecode(body);
}
''';
}

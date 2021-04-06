import 'dart:convert';

class Log {
  final String comment;
  final List<Entry> entries;

  Log.fromJson(Map<String, dynamic> json)
      : comment = json['comment'],
        entries = Entry.fromList(json['entries']);

  @override
  String toString() {
    return 'Log{comment: $comment, entries: $entries}';
  }
}

class Entry {
  final Request request;
  final DateTime startedDateTime;
  final Timings timings;
  final Response response;
  final Map<String, dynamic> cache;
  final String serverIPAddress;
  final int time;
  final String connection;

  Entry.fromJson(Map<String, dynamic> json)
      : request = Request.fromJson(json['request']),
        startedDateTime = DateTime.tryParse(json['startedDateTime']),
        timings = Timings.fromJson(json['timings']),
        response = Response.fromJson(json['response']),
        cache = json['cache'],
        serverIPAddress = json['serverIPAddress'],
        time = json['time'],
        connection = json['connection'];

  static List<Entry> fromList(List<dynamic> json) =>
      json.map((e) => Entry.fromJson(e)).toList();

  @override
  String toString() {
    return 'Entry{request: $request, startedDateTime: $startedDateTime, timings: $timings, response: $response, cache: $cache, serverIPAddress: $serverIPAddress, time: $time, connection: $connection}';
  }
}

class Request {
  final List<String> queryString;
  final int headersSize;
  final List<Cookie> cookies;
  final List<Header> headers;
  final String httpVersion;
  final String url;
  final PostData postData;
  final String method;
  final int bodySize;

  Request.fromJson(Map<String, dynamic> json)
      : queryString = List.castFrom<dynamic, String>(json['queryString']),
        headersSize = json['headersSize'],
        cookies = Cookie.fromList(json['cookies']),
        headers = Header.fromList(json['headers']),
        httpVersion = json['httpVersion'],
        url = json['url'],
        postData = PostData.fromJson(json['postData']),
        method = json['method'],
        bodySize = json['bodySize'];

  @override
  String toString() {
    return 'Request{queryString: $queryString, headersSize: $headersSize, cookies: $cookies, headers: $headers, httpVersion: $httpVersion, url: $url, postData: $postData, method: $method, bodySize: $bodySize}';
  }
}

class Response {
  final String statusText;
  final int headersSize;
  final List<Cookie> cookies;
  final ResponseContent content;
  final List<Header> headers;
  final String httpVersion;
  final int status;
  final String redirectUrl;
  final int bodySize;

  Response.fromJson(Map<String, dynamic> json)
      : statusText = json['statusText'],
        headersSize = json['headersSize'],
        cookies = Cookie.fromList(json['cookies']),
        content = ResponseContent.fromJson(json['content']),
        headers = Header.fromList(json['headers']),
        httpVersion = json['httpVersion'],
        status = json['status'],
        redirectUrl = json['redirectUrl'],
        bodySize = json['bodySize'];

  @override
  String toString() {
    return 'Response{statusText: $statusText, headersSize: $headersSize, cookies: $cookies, content: $content, headers: $headers, httpVersion: $httpVersion, status: $status, redirectUrl: $redirectUrl, bodySize: $bodySize}';
  }
}

class Timings {
  final int send;
  final int blocked;
  final int ssl;
  final int wait;
  final int receive;
  final int connect;
  final int dns;

  Timings.fromJson(Map<String, dynamic> json)
      : send = json['send'],
        blocked = json['blocked'],
        ssl = json['ssl'],
        wait = json['wait'],
        receive = json['receive'],
        connect = json['connect'],
        dns = json['dns'];

  @override
  String toString() {
    return 'Timings{send: $send, blocked: $blocked, ssl: $ssl, wait: $wait, receive: $receive, connect: $connect, dns: $dns}';
  }
}

class ResponseContent {
  final int compression;
  final String mimeType;
  final String text;
  final int size;

  dynamic get json => (text?.isEmpty ?? true) ? {} : jsonDecode(text);

  ResponseContent.fromJson(Map<String, dynamic> json)
      : compression = json['compression'],
        mimeType = json['mimeType'],
        text = json['text'],
        size = json['size'];

  @override
  String toString() {
    return 'ResponseContent{compression: $compression, mimeType: $mimeType, text: $text, size: $size}';
  }
}

class Cookie {
  final String name;
  final String value;

  Cookie.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        value = json['value'];

  static List<Cookie> fromList(List<dynamic> json) =>
      json.map((e) => Cookie.fromJson(e)).toList();

  @override
  String toString() {
    return 'Cookie{name: $name, value: $value}';
  }
}

class Header {
  final String name;
  final String value;

  Header.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        value = json['value'];

  static List<Header> fromList(List<dynamic> json) =>
      json.map((e) => Header.fromJson(e)).toList();

  @override
  String toString() {
    return 'Header{name: $name, value: $value}';
  }
}

class PostData {
  final String mimeType;
  final String text;

  dynamic get json => (text?.isEmpty ?? true) ? {} : jsonDecode(text);

  PostData.fromJson(Map<String, dynamic> json)
      : mimeType = json['mimeType'],
        text = json['text'];

  @override
  String toString() {
    return 'PostData{mimeType: $mimeType, text: $text}';
  }
}

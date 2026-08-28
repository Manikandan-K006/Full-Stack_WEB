import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';

/// Thin HTTP client wrapper that attaches the JWT token and decodes the
/// standard backend envelope: { "success": bool, "message": str, "data": ... }
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String errorCode;

  ApiException(this.statusCode, this.message, this.errorCode);

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  String _token = '';

  String get token => _token;
  set token(String value) => _token = value;

  bool get hasToken => _token.isNotEmpty;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(AppConstants.apiBaseUrl);
    final basePart = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final pathPart = path.startsWith('/') ? path.substring(1) : path;
    return base.replace(
      path: '$basePart/$pathPart',
      queryParameters: query == null || query.isEmpty ? null : query.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => http.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, {Object? body}) =>
      _send(() => http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> put(String path, {Object? body}) =>
      _send(() => http.put(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> delete(String path) => _send(() => http.delete(_uri(path), headers: _headers));

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response response;
    try {
      response = await request().timeout(const Duration(seconds: 25));
    } on Exception {
      throw ApiException(
        0,
        'Cannot reach the server at ${AppConstants.apiBaseUrl}. '
        'Please make sure the backend is running.',
        'NETWORK_ERROR',
      );
    }
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(response.statusCode, 'Unexpected response from the server', 'PARSE_ERROR');
    }

    final success = body['success'] == true;
    if (!success) {
      throw ApiException(
        response.statusCode,
        (body['message'] as String?) ?? 'Request failed',
        (body['error'] as String?) ?? 'ERROR',
      );
    }
    return body['data'];
  }
}

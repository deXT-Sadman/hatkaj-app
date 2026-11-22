import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

/// Thin JSON-over-HTTP wrapper. Repositories talk to this, never to `http` directly.
class ApiClient {
  ApiClient({String? baseUrl, http.Client? client})
    : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  /// Sent as a bearer token on every request while set.
  String? authToken;

  /// Called when the server rejects the current token (HTTP 401), so the app can sign out.
  void Function()? onUnauthorized;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) {
    return _send(() => _client.get(_uri(path, query), headers: _headers));
  }

  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic> body = const {},
  ]) {
    return _send(
      () => _client.post(_uri(path), headers: _headers, body: jsonEncode(body)),
    );
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) {
    return _send(
      () => _client.put(_uri(path), headers: _headers, body: jsonEncode(body)),
    );
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) {
    return _send(
      () =>
          _client.patch(_uri(path), headers: _headers, body: jsonEncode(body)),
    );
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$_baseUrl/api$path').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    final http.Response response;
    try {
      response = await request().timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw const ApiException('The server took too long to respond.');
    } on http.ClientException {
      throw const ApiException(
        'Cannot reach the server. Check your connection.',
      );
    }

    final body = _decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    if (response.statusCode == 401 && authToken != null) {
      onUnauthorized?.call();
    }
    throw ApiException(
      body['message'] as String? ??
          'Something went wrong (${response.statusCode}).',
      statusCode: response.statusCode,
      fieldErrors: _parseFieldErrors(body['errors']),
    );
  }

  Map<String, dynamic> _decode(String raw) {
    if (raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } on FormatException {
      return {};
    }
  }

  Map<String, List<String>> _parseFieldErrors(Object? errors) {
    if (errors is! Map) return {};
    return {
      for (final entry in errors.entries)
        entry.key as String: [
          for (final m in entry.value as List) m.toString(),
        ],
    };
  }
}

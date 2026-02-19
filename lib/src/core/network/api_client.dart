import 'dart:convert';

import 'package:http/http.dart' as http;

import '../logging/app_logger.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({required String baseUrl, required http.Client httpClient})
    : _baseUrl = baseUrl,
      _httpClient = httpClient;

  final String _baseUrl;
  final http.Client _httpClient;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
    String? bearerToken,
  }) async {
    final payload = await getAny(path, query: query, bearerToken: bearerToken);
    return _expectMap(payload);
  }

  Future<List<Map<String, dynamic>>> getJsonList(
    String path, {
    Map<String, dynamic>? query,
    String? bearerToken,
  }) async {
    final payload = await getAny(path, query: query, bearerToken: bearerToken);
    return _expectListOfMaps(payload);
  }

  Future<dynamic> getAny(
    String path, {
    Map<String, dynamic>? query,
    String? bearerToken,
  }) async {
    final uri = _buildUri(path, query);
    final headers = _headers(bearerToken: bearerToken);
    return _executeRequest(
      method: 'GET',
      uri: uri,
      headers: headers,
      send: () => _httpClient.get(uri, headers: headers),
    );
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    String? bearerToken,
  }) async {
    final payload = await postAny(
      path,
      query: query,
      body: body,
      bearerToken: bearerToken,
    );
    return _expectMap(payload);
  }

  Future<List<Map<String, dynamic>>> postJsonList(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    String? bearerToken,
  }) async {
    final payload = await postAny(
      path,
      query: query,
      body: body,
      bearerToken: bearerToken,
    );
    return _expectListOfMaps(payload);
  }

  Future<dynamic> postAny(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    String? bearerToken,
  }) async {
    final uri = _buildUri(path, query);
    final headers = _headers(bearerToken: bearerToken);
    final payload = body ?? <String, dynamic>{};

    return _executeRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: payload,
      send: () =>
          _httpClient.post(uri, headers: headers, body: jsonEncode(payload)),
    );
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    String? bearerToken,
  }) async {
    final payload = await patchAny(
      path,
      query: query,
      body: body,
      bearerToken: bearerToken,
    );
    return _expectMap(payload);
  }

  Future<dynamic> patchAny(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    String? bearerToken,
  }) async {
    final uri = _buildUri(path, query);
    final headers = _headers(bearerToken: bearerToken);
    final payload = body ?? <String, dynamic>{};

    return _executeRequest(
      method: 'PATCH',
      uri: uri,
      headers: headers,
      body: payload,
      send: () =>
          _httpClient.patch(uri, headers: headers, body: jsonEncode(payload)),
    );
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    String? bearerToken,
  }) async {
    final payload = await deleteAny(
      path,
      query: query,
      body: body,
      bearerToken: bearerToken,
    );
    return _expectMap(payload);
  }

  Future<dynamic> deleteAny(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    String? bearerToken,
  }) async {
    final uri = _buildUri(path, query);
    final headers = _headers(bearerToken: bearerToken);
    final payload = body;

    return _executeRequest(
      method: 'DELETE',
      uri: uri,
      headers: headers,
      body: payload,
      send: () => _httpClient.delete(
        uri,
        headers: headers,
        body: payload == null ? null : jsonEncode(payload),
      ),
    );
  }

  Future<dynamic> _executeRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
    required Future<http.Response> Function() send,
  }) async {
    _logRequest(method, uri, headers: headers, body: body);

    try {
      final response = await send();
      _logResponse(method, uri, response);
      return _decode(response);
    } on ApiException {
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Request failed: $method $uri',
        error: error,
        stackTrace: stackTrace,
      );
      throw ApiException('Network request failed', details: error.toString());
    }
  }

  Uri _buildUri(String path, Map<String, dynamic>? query) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final baseUri = Uri.parse('$_baseUrl$normalizedPath');

    if (query == null || query.isEmpty) {
      return baseUri;
    }

    final queryParametersAll = <String, List<String>>{};

    query.forEach((key, value) {
      if (value == null) {
        return;
      }

      if (value is Iterable) {
        final values = value
            .where((item) => item != null)
            .map((item) => item.toString())
            .toList();
        if (values.isNotEmpty) {
          queryParametersAll[key] = values;
        }
        return;
      }

      final text = value.toString();
      if (text.isNotEmpty) {
        queryParametersAll[key] = <String>[text];
      }
    });

    final queryParts = <String>[];
    queryParametersAll.forEach((key, values) {
      for (final value in values) {
        final encodedKey = Uri.encodeQueryComponent(key);
        final encodedValue = Uri.encodeQueryComponent(value);
        queryParts.add('$encodedKey=$encodedValue');
      }
    });

    final queryString = queryParts.join('&');
    return baseUri.replace(query: queryString.isEmpty ? null : queryString);
  }

  Map<String, String> _headers({String? bearerToken}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (bearerToken != null && bearerToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $bearerToken';
    }

    return headers;
  }

  dynamic _decode(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) {
        return <String, dynamic>{};
      }

      final dynamic decoded;
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        throw ApiException(
          'Invalid JSON response from server',
          statusCode: statusCode,
          details: _truncate(body),
        );
      }

      return decoded;
    }

    throw _toApiException(statusCode, body);
  }

  ApiException _toApiException(int statusCode, String body) {
    String message = 'Request failed with status $statusCode';
    String? details;

    if (body.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          final decodedMessage = decoded['message'];
          if (decodedMessage is String && decodedMessage.isNotEmpty) {
            message = decodedMessage;
          }

          final decodedDetails =
              decoded['error'] ??
              decoded['details'] ??
              decoded['errors'] ??
              decoded['path'];
          if (decodedDetails != null) {
            details = decodedDetails.toString();
          }
        } else {
          details = _truncate(body);
        }
      } catch (_) {
        details = _truncate(body);
      }
    }

    return ApiException(message, statusCode: statusCode, details: details);
  }

  void _logRequest(
    String method,
    Uri uri, {
    required Map<String, String> headers,
    Object? body,
  }) {
    AppLogger.debug('HTTP $method $uri');
    AppLogger.debug('Request headers: ${_sanitizeHeaders(headers)}');
    if (body != null) {
      final sanitized = _sanitizePayload(body);
      AppLogger.debug('Request body: ${_truncate(jsonEncode(sanitized))}');
    }
  }

  void _logResponse(String method, Uri uri, http.Response response) {
    AppLogger.debug('HTTP $method $uri -> ${response.statusCode}');
    if (response.body.isNotEmpty) {
      AppLogger.debug('Response body: ${_truncate(response.body)}');
    }
  }

  Map<String, String> _sanitizeHeaders(Map<String, String> headers) {
    final sanitized = <String, String>{...headers};
    sanitized.updateAll((key, value) {
      if (key.toLowerCase() == 'authorization') {
        return 'Bearer ***';
      }
      return value;
    });
    return sanitized;
  }

  Object? _sanitizePayload(Object? payload) {
    if (payload is Map<String, dynamic>) {
      final sanitized = <String, dynamic>{};
      payload.forEach((key, value) {
        final lowerKey = key.toLowerCase();
        if (lowerKey.contains('password') || lowerKey.contains('token')) {
          sanitized[key] = '***';
        } else {
          sanitized[key] = _sanitizePayload(value);
        }
      });
      return sanitized;
    }

    if (payload is List) {
      return payload.map(_sanitizePayload).toList();
    }

    return payload;
  }

  String _truncate(String value, {int maxChars = 1200}) {
    if (value.length <= maxChars) {
      return value;
    }
    return '${value.substring(0, maxChars)}...';
  }

  Map<String, dynamic> _expectMap(Object? payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    throw ApiException(
      'Unexpected response payload',
      details: 'Expected JSON object but received ${payload.runtimeType}',
    );
  }

  List<Map<String, dynamic>> _expectListOfMaps(Object? payload) {
    if (payload is! List) {
      throw ApiException(
        'Unexpected response payload',
        details: 'Expected JSON array but received ${payload.runtimeType}',
      );
    }

    final result = <Map<String, dynamic>>[];
    for (final item in payload) {
      if (item is Map<String, dynamic>) {
        result.add(item);
      }
    }
    return result;
  }
}

import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/app_environment.dart';
import '../logging/app_logger.dart';
import 'api_exception.dart';

/// Centralised Dio wrapper.
///
/// All feature-level API classes use [ApiClient] which in turn delegates to
/// this class.  Do NOT call Dio directly from ViewModels or feature files.
class DioClient {
  DioClient({String? baseUrl, bool enableLogging = false}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppEnvironment.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json; charset=utf-8',
        responseType: ResponseType.json,
      ),
    );

    if (enableLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          logPrint: (obj) => AppLogger.debug(obj.toString()),
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException err, ErrorInterceptorHandler handler) {
          handler.next(err);
        },
      ),
    );
  }

  late final Dio _dio;

  // ─────────────────────────── GET ────────────────────────────

  Future<dynamic> getAny(
    String path, {
    Map<String, dynamic>? query,
    String? bearerToken,
  }) async {
    return _execute(
      () => _dio.get<dynamic>(
        path,
        queryParameters: _cleanQuery(query),
        options: _options(bearerToken),
      ),
    );
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
    String? bearerToken,
  }) async {
    final data = await getAny(path, query: query, bearerToken: bearerToken);
    return _expectMap(data);
  }

  // ─────────────────────────── POST ────────────────────────────

  Future<dynamic> postAny(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    String? bearerToken,
  }) async {
    return _execute(
      () => _dio.post<dynamic>(
        path,
        queryParameters: _cleanQuery(query),
        data: body,
        options: _options(bearerToken),
      ),
    );
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    String? bearerToken,
  }) async {
    final data = await postAny(
      path,
      query: query,
      body: body,
      bearerToken: bearerToken,
    );
    return _expectMap(data);
  }

  // ─────────────────────────── PATCH ────────────────────────────

  Future<dynamic> patchAny(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    String? bearerToken,
  }) async {
    return _execute(
      () => _dio.patch<dynamic>(
        path,
        queryParameters: _cleanQuery(query),
        data: body,
        options: _options(bearerToken),
      ),
    );
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    String? bearerToken,
  }) async {
    final data = await patchAny(
      path,
      query: query,
      body: body,
      bearerToken: bearerToken,
    );
    return _expectMap(data);
  }

  // ─────────────────────────── DELETE ────────────────────────────

  Future<dynamic> deleteAny(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    String? bearerToken,
  }) async {
    return _execute(
      () => _dio.delete<dynamic>(
        path,
        queryParameters: _cleanQuery(query),
        data: body,
        options: _options(bearerToken),
      ),
    );
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    String? bearerToken,
  }) async {
    final data = await deleteAny(
      path,
      query: query,
      body: body,
      bearerToken: bearerToken,
    );
    return _expectMap(data);
  }

  // ─────────────────────────── MULTIPART ────────────────────────────

  /// Upload a file via multipart POST.
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String bearerToken,
    required String fieldName,
    required String fileName,
    required Uint8List fileBytes,
    Map<String, dynamic>? query,
  }) async {
    final formData = FormData.fromMap(<String, dynamic>{
      fieldName: MultipartFile.fromBytes(fileBytes, filename: fileName),
    });

    final data = await _execute(
      () => _dio.post<dynamic>(
        path,
        queryParameters: _cleanQuery(query),
        data: formData,
        options: Options(
          headers: <String, String>{'Authorization': 'Bearer $bearerToken'},
          contentType: 'multipart/form-data',
        ),
      ),
    );
    return _expectMap(data);
  }

  // ─────────────────────────── HELPERS ────────────────────────────

  Options _options(String? bearerToken) {
    if (bearerToken != null && bearerToken.isNotEmpty) {
      return Options(
        headers: <String, String>{'Authorization': 'Bearer $bearerToken'},
      );
    }
    return Options();
  }

  /// Removes null values from query map; Dio handles list params natively.
  Map<String, dynamic>? _cleanQuery(Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return null;
    return Map<String, dynamic>.fromEntries(
      query.entries.where((e) {
        final val = e.value;
        if (val == null) return false;
        if (val is Iterable && val.isEmpty) return false;
        if (val is String && val.isEmpty) return false;
        return true;
      }),
    );
  }

  Future<dynamic> _execute(Future<Response<dynamic>> Function() send) async {
    try {
      final response = await send();
      return response.data;
    } on DioException catch (err, stackTrace) {
      AppLogger.error(
        'DioException: ${err.requestOptions.method} ${err.requestOptions.path}',
        error: err,
        stackTrace: stackTrace,
      );
      throw ApiException.fromDioException(err);
    } catch (err, stackTrace) {
      AppLogger.error('Unexpected network error', error: err, stackTrace: stackTrace);
      throw ApiException('Network request failed', details: err.toString());
    }
  }

  Map<String, dynamic> _expectMap(Object? payload) {
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    throw ApiException(
      'Unexpected response payload',
      details: 'Expected JSON object but received ${payload.runtimeType}',
    );
  }
}

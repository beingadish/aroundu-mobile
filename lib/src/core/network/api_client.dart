import 'dart:typed_data';

import 'dio_client.dart';

/// Thin façade over [DioClient] that preserves the same interface used by all
/// feature-level API classes (AuthApi, JobApi, UserProfileApi, etc.).
///
/// This layer exists so that feature files never import Dio directly and the
/// underlying HTTP client can be swapped without touching feature code.
class ApiClient {
  ApiClient({required DioClient dioClient}) : _dio = dioClient;

  final DioClient _dio;

  // ─────────────────────────── GET ────────────────────────────

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
    String? bearerToken,
  }) =>
      _dio.getJson(path, query: query, bearerToken: bearerToken);

  Future<dynamic> getAny(
    String path, {
    Map<String, dynamic>? query,
    String? bearerToken,
  }) =>
      _dio.getAny(path, query: query, bearerToken: bearerToken);

  // ─────────────────────────── POST ────────────────────────────

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    String? bearerToken,
  }) =>
      _dio.postJson(path, query: query, body: body, bearerToken: bearerToken);

  Future<dynamic> postAny(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    String? bearerToken,
  }) =>
      _dio.postAny(path, query: query, body: body, bearerToken: bearerToken);

  // ─────────────────────────── PATCH ────────────────────────────

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    String? bearerToken,
  }) =>
      _dio.patchJson(path, query: query, body: body, bearerToken: bearerToken);

  // ─────────────────────────── DELETE ────────────────────────────

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    String? bearerToken,
  }) =>
      _dio.deleteJson(path, query: query, body: body, bearerToken: bearerToken);

  Future<dynamic> deleteAny(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    String? bearerToken,
  }) =>
      _dio.deleteAny(path, query: query, body: body, bearerToken: bearerToken);

  // ─────────────────────────── MULTIPART ────────────────────────────

  /// Upload a file via multipart POST.
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String bearerToken,
    required String fieldName,
    required String fileName,
    required Uint8List fileBytes,
    Map<String, dynamic>? query,
  }) =>
      _dio.postMultipart(
        path,
        bearerToken: bearerToken,
        fieldName: fieldName,
        fileName: fileName,
        fileBytes: fileBytes,
        query: query,
      );
}

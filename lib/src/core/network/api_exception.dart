import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final String? details;

  /// Convert a [DioException] into a structured [ApiException].
  factory ApiException.fromDioException(DioException err) {
    final response = err.response;
    final statusCode = response?.statusCode;

    // Try to extract backend message from ApiResponse envelope
    String message = _defaultMessage(err.type, statusCode);
    String? details;

    if (response != null) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        final serverMsg = body['message'];
        if (serverMsg is String && serverMsg.isNotEmpty) {
          message = serverMsg;
        }
        final serverDetails =
            body['error'] ?? body['details'] ?? body['errors'];
        if (serverDetails != null) {
          details = serverDetails.toString();
        }
      }
    }

    return ApiException(message, statusCode: statusCode, details: details);
  }

  static String _defaultMessage(DioExceptionType type, int? statusCode) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your network and try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to the server. Check your network.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badResponse:
        return _messageForStatus(statusCode);
      default:
        return 'Network request failed.';
    }
  }

  static String _messageForStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'Resource not found.';
      case 409:
        return 'Conflict: the action cannot be completed in the current state.';
      case 413:
        return 'File too large. Maximum size is 5 MB.';
      case 422:
        return 'Validation error. Please review your input.';
      case 429:
        return 'Too many requests. Please wait and try again.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Server error. Please try again later.';
      default:
        return 'Request failed with status $statusCode';
    }
  }

  /// User-visible message with HTTP code/details when available.
  String get userMessage {
    final status = statusCode == null ? '' : ' (HTTP $statusCode)';
    final detailText = details?.trim();
    if (detailText == null || detailText.isEmpty) {
      return '$message$status';
    }
    return '$message$status: $detailText';
  }

  @override
  String toString() {
    final status = statusCode == null ? '' : ' (HTTP $statusCode)';
    final detail = details == null || details!.isEmpty ? '' : ': $details';
    return '$message$status$detail';
  }
}

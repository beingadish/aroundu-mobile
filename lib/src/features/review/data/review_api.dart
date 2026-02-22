import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class ReviewApi {
  const ReviewApi(this._client);

  final ApiClient _client;

  /// Submit a review for a completed job (CLIENT only)
  Future<Map<String, dynamic>> submitReview({
    required String token,
    required int jobId,
    required int clientId,
    required double rating,
    String? reviewComment,
  }) async {
    final response = await _client.postAny(
      '/api/v1/reviews/jobs/$jobId',
      bearerToken: token,
      query: <String, dynamic>{'clientId': clientId},
      body: <String, dynamic>{
        'rating': rating,
        if (reviewComment != null && reviewComment.trim().isNotEmpty)
          'reviewComment': reviewComment.trim(),
      },
    );

    return _readMapPayload(response);
  }

  /// Get all reviews for a worker (public)
  Future<List<Map<String, dynamic>>> getWorkerReviews({
    required int workerId,
    String? token,
  }) async {
    final response = await _client.getAny(
      '/api/v1/reviews/workers/$workerId',
      bearerToken: token,
    );

    return _readListPayload(response);
  }

  /// Get the review for a specific job
  Future<Map<String, dynamic>> getJobReview({
    required int jobId,
    String? token,
  }) async {
    final response = await _client.getAny(
      '/api/v1/reviews/jobs/$jobId',
      bearerToken: token,
    );

    return _readMapPayload(response);
  }

  /// Submit a review as a WORKER (worker → client review)
  Future<Map<String, dynamic>> submitWorkerReview({
    required String token,
    required int jobId,
    required int workerId,
    required double rating,
    String? reviewComment,
  }) async {
    final response = await _client.postAny(
      '/api/v1/reviews/jobs/$jobId/worker',
      bearerToken: token,
      query: <String, dynamic>{'workerId': workerId},
      body: <String, dynamic>{
        'rating': rating,
        if (reviewComment != null && reviewComment.trim().isNotEmpty)
          'reviewComment': reviewComment.trim(),
      },
    );

    return _readMapPayload(response);
  }

  /// Check whether a user has already reviewed a job.
  Future<bool> checkReviewEligibility({
    required String token,
    required int jobId,
    required int userId,
  }) async {
    final response = await _client.getAny(
      '/api/v1/reviews/jobs/$jobId/eligibility',
      bearerToken: token,
      query: <String, dynamic>{'userId': userId},
    );

    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return data['eligible'] == true;
      }
    }
    return false;
  }

  Map<String, dynamic> _readMapPayload(Object? payload) {
    if (payload is Map<String, dynamic>) {
      if (payload.containsKey('success')) {
        final success = payload['success'];
        if (success == true) {
          final data = payload['data'];
          if (data is Map<String, dynamic>) return data;
          return payload;
        }
        throw ApiException(payload['message']?.toString() ?? 'Request failed');
      }
      return payload;
    }
    throw const ApiException('Malformed response payload');
  }

  List<Map<String, dynamic>> _readListPayload(Object? payload) {
    if (payload is List) {
      return payload
          .whereType<Map<String, dynamic>>()
          .map((item) => <String, dynamic>{...item})
          .toList();
    }

    if (payload is Map<String, dynamic> && payload.containsKey('success')) {
      final success = payload['success'];
      if (success == true) {
        final data = payload['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((item) => <String, dynamic>{...item})
              .toList();
        }
      }
      throw ApiException(payload['message']?.toString() ?? 'Request failed');
    }

    throw const ApiException('Malformed response payload');
  }
}

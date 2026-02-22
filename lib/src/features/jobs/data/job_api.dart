import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class JobApi {
  const JobApi(this._client);

  final ApiClient _client;

  // ───────────────────────── Jobs ─────────────────────────
  Future<List<Map<String, dynamic>>> fetchClientJobs({
    required String token,
    required int clientId,
    int page = 0,
    int size = 20,
    List<String>? statuses,
    String sortBy = 'createdAt',
    String sortDirection = 'DESC',
    String? startDate,
    String? endDate,
    bool sortByDistance = false,
    double? distanceLatitude,
    double? distanceLongitude,
  }) async {
    final response = await _client.getJson(
      '/api/v1/jobs/client/$clientId',
      bearerToken: token,
      query: <String, dynamic>{
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDirection': sortDirection,
        if (statuses != null && statuses.isNotEmpty) 'statuses': statuses,
        if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
        if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        if (sortByDistance) 'sortByDistance': true,
        if (distanceLatitude != null) 'distanceLatitude': distanceLatitude,
        if (distanceLongitude != null) 'distanceLongitude': distanceLongitude,
      },
    );

    return _readPageContent(response);
  }

  Future<List<Map<String, dynamic>>> fetchClientPastJobs({
    required String token,
    required int clientId,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.getJson(
      '/api/v1/jobs/client/$clientId/past',
      bearerToken: token,
      query: <String, dynamic>{'page': page, 'size': size},
    );

    return _readPageContent(response);
  }

  Future<List<Map<String, dynamic>>> fetchWorkerFeed({
    required String token,
    required int workerId,
    List<int> skillIds = const <int>[],
    int page = 0,
    int size = 20,
    String sortBy = 'createdAt',
    String sortDirection = 'DESC',
    double? radiusKm,
    bool sortByDistance = true,
  }) async {
    final response = await _client.getJson(
      '/api/v1/jobs/worker/$workerId/feed',
      bearerToken: token,
      query: <String, dynamic>{
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDirection': sortDirection,
        if (skillIds.isNotEmpty) 'skillIds': skillIds,
        if (radiusKm != null) 'radiusKm': radiusKm,
        if (sortByDistance) 'sortByDistance': true,
      },
    );

    return _readPageContent(response);
  }

  Future<Map<String, dynamic>> fetchJobForClient({
    required String token,
    required int clientId,
    required int jobId,
  }) async {
    final response = await _client.getJson(
      '/api/v1/jobs/client/$clientId/$jobId',
      bearerToken: token,
    );
    return _readDataMap(response);
  }

  Future<Map<String, dynamic>> fetchJobForWorker({
    required String token,
    required int workerId,
    required int jobId,
  }) async {
    final response = await _client.getJson(
      '/api/v1/jobs/worker/$workerId/$jobId',
      bearerToken: token,
    );
    return _readDataMap(response);
  }

  Future<Map<String, dynamic>> fetchPublicJob(int jobId) async {
    final response = await _client.getJson('/api/v1/jobs/$jobId');
    return _readDataMap(response);
  }

  Future<List<Map<String, dynamic>>> searchJobs({
    String? city,
    String? area,
    List<int>? skillIds,
  }) async {
    final response = await _client.getJson(
      '/api/v1/jobs',
      query: <String, dynamic>{
        if (city != null && city.isNotEmpty) 'city': city,
        if (area != null && area.isNotEmpty) 'area': area,
        if (skillIds != null && skillIds.isNotEmpty) 'skillIds': skillIds,
      },
    );
    return _readDataList(response);
  }

  Future<Map<String, dynamic>> createJob({
    required String token,
    required int clientId,
    required int jobLocationId,
    required String title,
    required String description,
    required String currency,
    required double amount,
    List<int> skillIds = const <int>[],
    List<String> skillNames = const <String>[],
    String jobUrgency = 'NORMAL',
    String paymentMode = 'OFFLINE',
  }) async {
    final shortDescription = description.length <= 120
        ? description
        : description.substring(0, 120);

    final body = <String, dynamic>{
      'title': title,
      'shortDescription': shortDescription,
      'longDescription': description,
      'price': <String, dynamic>{
        'currency': currency.toUpperCase(),
        'amount': amount,
      },
      'jobLocationId': jobLocationId,
      'jobUrgency': jobUrgency,
      'paymentMode': paymentMode,
    };

    // Prefer skill names (auto-create on backend) over IDs
    if (skillNames.isNotEmpty) {
      body['requiredSkillNames'] = skillNames;
    } else if (skillIds.isNotEmpty) {
      body['requiredSkillIds'] = skillIds;
    }

    final response = await _client.postJson(
      '/api/v1/jobs',
      bearerToken: token,
      query: <String, dynamic>{'clientId': clientId},
      body: body,
    );

    return _readDataMap(response);
  }

  Future<Map<String, dynamic>> updateJob({
    required String token,
    required int clientId,
    required int jobId,
    String? title,
    String? shortDescription,
    String? longDescription,
    String? currency,
    double? amount,
    int? jobLocationId,
    String? jobUrgency,
    List<int>? requiredSkillIds,
    String? paymentMode,
  }) async {
    final payload = <String, dynamic>{
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (shortDescription != null && shortDescription.trim().isNotEmpty)
        'shortDescription': shortDescription.trim(),
      if (longDescription != null && longDescription.trim().isNotEmpty)
        'longDescription': longDescription.trim(),
      if (jobLocationId != null) 'jobLocationId': jobLocationId,
      if (jobUrgency != null) 'jobUrgency': jobUrgency,
      if (requiredSkillIds != null && requiredSkillIds.isNotEmpty)
        'requiredSkillIds': requiredSkillIds,
      if (paymentMode != null) 'paymentMode': paymentMode,
    };

    if (currency != null && amount != null) {
      payload['price'] = <String, dynamic>{
        'currency': currency.toUpperCase(),
        'amount': amount,
      };
    }

    final response = await _client.patchJson(
      '/api/v1/jobs/$jobId',
      bearerToken: token,
      query: <String, dynamic>{'clientId': clientId},
      body: payload,
    );

    return _readDataMap(response);
  }

  Future<Map<String, dynamic>> updateJobStatus({
    required String token,
    required int clientId,
    required int jobId,
    required String newStatus,
  }) async {
    final response = await _client.patchJson(
      '/api/v1/jobs/$jobId/status',
      bearerToken: token,
      query: <String, dynamic>{'clientId': clientId},
      body: <String, dynamic>{'newStatus': newStatus},
    );

    return _readDataMap(response);
  }

  Future<void> deleteJob({
    required String token,
    required int clientId,
    required int jobId,
  }) async {
    final response = await _client.deleteJson(
      '/api/v1/jobs/$jobId',
      bearerToken: token,
      query: <String, dynamic>{'clientId': clientId},
    );

    _ensureSuccessEnvelope(response);
  }

  /// Worker updates job status (IN_PROGRESS or COMPLETED_PENDING_PAYMENT).
  Future<Map<String, dynamic>> updateJobStatusByWorker({
    required String token,
    required int workerId,
    required int jobId,
    required String newStatus,
  }) async {
    final response = await _client.patchJson(
      '/api/v1/jobs/$jobId/worker-status',
      bearerToken: token,
      query: <String, dynamic>{'workerId': workerId},
      body: <String, dynamic>{'newStatus': newStatus},
    );

    return _readDataMap(response);
  }

  // ───────────────────────── Bids ─────────────────────────
  Future<Map<String, dynamic>> placeBid({
    required String token,
    required int jobId,
    required int workerId,
    required double bidAmount,
    String? partnerName,
    double? partnerFee,
    String? notes,
  }) async {
    final response = await _client.postAny(
      '/api/v1/bid/jobs/$jobId/bids',
      bearerToken: token,
      query: <String, dynamic>{'workerId': workerId},
      body: <String, dynamic>{
        'bidAmount': bidAmount,
        if (partnerName != null && partnerName.trim().isNotEmpty)
          'partnerName': partnerName.trim(),
        if (partnerFee != null) 'partnerFee': partnerFee,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );

    return _readMapPayload(response);
  }

  Future<List<Map<String, dynamic>>> listBidsForJob({
    required String token,
    required int jobId,
  }) async {
    final response = await _client.getAny(
      '/api/v1/bid/jobs/$jobId/bids',
      bearerToken: token,
    );

    return _readListPayload(response);
  }

  Future<Map<String, dynamic>> acceptBid({
    required String token,
    required int bidId,
    required int clientId,
  }) async {
    final response = await _client.postAny(
      '/api/v1/bid/bids/$bidId/accept',
      bearerToken: token,
      query: <String, dynamic>{'clientId': clientId},
    );

    return _readMapPayload(response);
  }

  Future<Map<String, dynamic>> handshakeBid({
    required String token,
    required int bidId,
    required int workerId,
    required bool accepted,
  }) async {
    final response = await _client.postAny(
      '/api/v1/bid/bids/$bidId/handshake',
      bearerToken: token,
      query: <String, dynamic>{'workerId': workerId},
      body: <String, dynamic>{'accepted': accepted},
    );

    return _readMapPayload(response);
  }

  // ──────────────────────── Job Codes ────────────────────────
  Future<Map<String, dynamic>> generateJobCodes({
    required String token,
    required int jobId,
    required int clientId,
  }) async {
    final response = await _client.postAny(
      '/api/v1/jobs/$jobId/codes',
      bearerToken: token,
      query: <String, dynamic>{'clientId': clientId},
    );

    return _readMapPayload(response);
  }

  Future<Map<String, dynamic>> verifyStartCode({
    required String token,
    required int jobId,
    required int workerId,
    required String code,
  }) async {
    final response = await _client.postAny(
      '/api/v1/jobs/$jobId/codes/start',
      bearerToken: token,
      query: <String, dynamic>{'workerId': workerId},
      body: <String, dynamic>{'code': code},
    );

    return _readMapPayload(response);
  }

  Future<Map<String, dynamic>> verifyReleaseCode({
    required String token,
    required int jobId,
    required int clientId,
    required String code,
  }) async {
    final response = await _client.postAny(
      '/api/v1/jobs/$jobId/codes/release',
      bearerToken: token,
      query: <String, dynamic>{'clientId': clientId},
      body: <String, dynamic>{'code': code},
    );

    return _readMapPayload(response);
  }

  /// Regenerate OTP codes (invalidates old, creates new). Rate-limited to 1/min.
  Future<Map<String, dynamic>> regenerateJobCodes({
    required String token,
    required int jobId,
    required int clientId,
  }) async {
    final response = await _client.postAny(
      '/api/v1/jobs/$jobId/otp/regenerate',
      bearerToken: token,
      query: <String, dynamic>{'clientId': clientId},
    );

    return _readMapPayload(response);
  }

  /// Worker cancels an accepted/in-progress job. Triggers cancellation penalty.
  Future<Map<String, dynamic>> cancelJobByWorker({
    required String token,
    required int workerId,
    required int jobId,
  }) async {
    final response = await _client.postAny(
      '/api/v1/jobs/$jobId/worker-cancel',
      bearerToken: token,
      query: <String, dynamic>{'workerId': workerId},
    );

    return _readMapPayload(response);
  }

  // ──────────────────────── Payments ────────────────────────
  Future<Map<String, dynamic>> lockEscrowPayment({
    required String token,
    required int jobId,
    required int clientId,
    required double amount,
  }) async {
    final response = await _client.postAny(
      '/api/v1/jobs/$jobId/payments/lock',
      bearerToken: token,
      query: <String, dynamic>{'clientId': clientId},
      body: <String, dynamic>{'amount': amount},
    );

    return _readMapPayload(response);
  }

  Future<Map<String, dynamic>> releaseEscrowPayment({
    required String token,
    required int jobId,
    required int clientId,
    required String releaseCode,
  }) async {
    final response = await _client.postAny(
      '/api/v1/jobs/$jobId/payments/release',
      bearerToken: token,
      query: <String, dynamic>{'clientId': clientId},
      body: <String, dynamic>{'releaseCode': releaseCode},
    );

    return _readMapPayload(response);
  }

  List<Map<String, dynamic>> _readPageContent(Map<String, dynamic> envelope) {
    final data = _readDataMap(envelope);
    final content = data['content'];

    if (content is! List) {
      return const <Map<String, dynamic>>[];
    }

    final results = <Map<String, dynamic>>[];
    for (final item in content) {
      if (item is Map<String, dynamic>) {
        results.add(item);
      }
    }

    return results;
  }

  List<Map<String, dynamic>> _readDataList(Map<String, dynamic> envelope) {
    _ensureSuccessEnvelope(envelope);

    final data = envelope['data'];
    if (data is! List) {
      return const <Map<String, dynamic>>[];
    }

    final mapped = <Map<String, dynamic>>[];
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        mapped.add(item);
      }
    }

    return mapped;
  }

  Map<String, dynamic> _readDataMap(Map<String, dynamic> envelope) {
    _ensureSuccessEnvelope(envelope);

    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    throw const ApiException('Malformed response payload');
  }

  Map<String, dynamic> _readMapPayload(Object? payload) {
    if (payload is Map<String, dynamic>) {
      if (payload.containsKey('success')) {
        final success = payload['success'];
        if (success == true) {
          final data = payload['data'];
          if (data is Map<String, dynamic>) {
            return data;
          }
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
      _ensureSuccessEnvelope(payload);
      final data = payload['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((item) => <String, dynamic>{...item})
            .toList();
      }
    }

    throw const ApiException('Malformed response payload');
  }

  void _ensureSuccessEnvelope(Map<String, dynamic> response) {
    final success = response['success'];
    if (success == true) {
      return;
    }

    throw ApiException(response['message']?.toString() ?? 'Request failed');
  }
}

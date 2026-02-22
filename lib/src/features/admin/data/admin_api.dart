import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

/// Platform statistics returned by the admin overview endpoint.
class AdminOverview {
  const AdminOverview({
    required this.totalClients,
    required this.totalWorkers,
    required this.activeJobs,
    required this.openJobs,
    required this.jobsCreatedToday,
    required this.jobsCompletedToday,
  });

  final int totalClients;
  final int totalWorkers;
  final int activeJobs;
  final int openJobs;
  final int jobsCreatedToday;
  final int jobsCompletedToday;

  factory AdminOverview.fromMap(Map<String, dynamic> map) {
    return AdminOverview(
      totalClients: _asInt(map['totalClients']),
      totalWorkers: _asInt(map['totalWorkers']),
      activeJobs: _asInt(map['activeJobs']),
      openJobs: _asInt(map['openJobs']),
      jobsCreatedToday: _asInt(map['jobsCreatedToday']),
      jobsCompletedToday: _asInt(map['jobsCompletedToday']),
    );
  }
}

/// Data source for admin-only endpoints.
class AdminApi {
  const AdminApi(this._client);

  final ApiClient _client;

  /// GET /api/v1/admin/overview — requires ROLE_ADMIN.
  Future<AdminOverview> fetchOverview(String bearerToken) async {
    final response = await _client.getJson(
      '/api/v1/admin/overview',
      bearerToken: bearerToken,
    );

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Malformed admin overview response');
    }

    return AdminOverview.fromMap(data);
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

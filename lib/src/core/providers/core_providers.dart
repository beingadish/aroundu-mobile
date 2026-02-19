import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/data/auth_api.dart';
import '../../features/jobs/data/job_api.dart';
import '../config/app_environment.dart';
import '../network/api_client.dart';
import '../storage/local_storage.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: AppEnvironment.apiBaseUrl,
    httpClient: ref.watch(httpClientProvider),
  );
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});

final jobApiProvider = Provider<JobApi>((ref) {
  return JobApi(ref.watch(apiClientProvider));
});

final localStorageProvider = Provider<LocalStorage>((ref) {
  return const LocalStorage();
});

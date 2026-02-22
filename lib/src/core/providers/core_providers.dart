import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_api.dart';
import '../../features/admin/data/admin_api.dart';
import '../../features/chat/data/chat_api.dart';
import '../../features/jobs/data/job_api.dart';
import '../../features/jobs/data/skill_api.dart';
import '../../features/profile/data/user_profile_api.dart';
import '../../features/review/data/review_api.dart';
import '../config/app_environment.dart';
import '../network/api_client.dart';
import '../network/dio_client.dart';
import '../storage/local_storage.dart';

/// Logging enabled when the app is compiled with
/// `--dart-define=ENABLE_LOGGING=true`.
const _loggingEnabled = bool.fromEnvironment('ENABLE_LOGGING');

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    baseUrl: AppEnvironment.apiBaseUrl,
    enableLogging: _loggingEnabled,
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(dioClient: ref.watch(dioClientProvider));
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});

final jobApiProvider = Provider<JobApi>((ref) {
  return JobApi(ref.watch(apiClientProvider));
});

final skillApiProvider = Provider<SkillApi>((ref) {
  return SkillApi(ref.watch(apiClientProvider));
});

final userProfileApiProvider = Provider<UserProfileApi>((ref) {
  return UserProfileApi(ref.watch(apiClientProvider));
});

final chatApiProvider = Provider<ChatApi>((ref) {
  return ChatApi(ref.watch(apiClientProvider));
});

final reviewApiProvider = Provider<ReviewApi>((ref) {
  return ReviewApi(ref.watch(apiClientProvider));
});

final adminApiProvider = Provider<AdminApi>((ref) {
  return AdminApi(ref.watch(apiClientProvider));
});

final localStorageProvider = Provider<LocalStorage>((ref) {
  return const LocalStorage();
});

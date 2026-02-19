import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_api.dart';
import 'auth_view_model.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';

class AdminUserItem {
  const AdminUserItem({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
  });

  final int id;
  final String name;
  final String email;
  final String phoneNumber;
  final UserRole role;

  factory AdminUserItem.fromProfile(UserProfileData profile, UserRole role) {
    return AdminUserItem(
      id: profile.id ?? 0,
      name: profile.name?.trim().isNotEmpty == true
          ? profile.name!
          : 'Unknown user',
      email: profile.email?.trim().isNotEmpty == true
          ? profile.email!
          : 'No email',
      phoneNumber: profile.phoneNumber?.trim().isNotEmpty == true
          ? profile.phoneNumber!
          : 'No phone',
      role: role,
    );
  }
}

abstract class AdminRepository {
  Future<List<AdminUserItem>> fetchClients();
  Future<List<AdminUserItem>> fetchWorkers();
  Future<void> deleteClient(int clientId);
  Future<void> deleteWorker(int workerId);
}

class ApiAdminRepository implements AdminRepository {
  const ApiAdminRepository({required AuthApi authApi, required AuthState auth})
    : _authApi = authApi,
      _auth = auth;

  final AuthApi _authApi;
  final AuthState _auth;

  @override
  Future<List<AdminUserItem>> fetchClients() async {
    _guardAdmin();

    final page = await _authApi.fetchAllClients(
      token: _auth.token!,
      page: 0,
      size: 100,
    );
    return page.users
        .map((profile) => AdminUserItem.fromProfile(profile, UserRole.provider))
        .toList();
  }

  @override
  Future<List<AdminUserItem>> fetchWorkers() async {
    _guardAdmin();

    final page = await _authApi.fetchAllWorkers(
      token: _auth.token!,
      page: 0,
      size: 100,
    );
    return page.users
        .map((profile) => AdminUserItem.fromProfile(profile, UserRole.worker))
        .toList();
  }

  @override
  Future<void> deleteClient(int clientId) async {
    _guardAdmin();
    await _authApi.deleteClient(token: _auth.token!, clientId: clientId);
  }

  @override
  Future<void> deleteWorker(int workerId) async {
    _guardAdmin();
    await _authApi.deleteWorker(token: _auth.token!, workerId: workerId);
  }

  void _guardAdmin() {
    if (!_auth.isAuthenticated || _auth.role != UserRole.admin) {
      throw const ApiException('Admin access is required');
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return ApiAdminRepository(
    authApi: ref.watch(authApiProvider),
    auth: ref.watch(authControllerProvider),
  );
});

class AdminClientsController extends AsyncNotifier<List<AdminUserItem>> {
  @override
  Future<List<AdminUserItem>> build() {
    return ref.read(adminRepositoryProvider).fetchClients();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).fetchClients(),
    );
  }

  Future<void> deleteClient(int clientId) async {
    await ref.read(adminRepositoryProvider).deleteClient(clientId);
    await refresh();
    ref.invalidate(adminWorkersControllerProvider);
  }
}

final adminClientsControllerProvider =
    AsyncNotifierProvider<AdminClientsController, List<AdminUserItem>>(
      AdminClientsController.new,
    );

class AdminWorkersController extends AsyncNotifier<List<AdminUserItem>> {
  @override
  Future<List<AdminUserItem>> build() {
    return ref.read(adminRepositoryProvider).fetchWorkers();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).fetchWorkers(),
    );
  }

  Future<void> deleteWorker(int workerId) async {
    await ref.read(adminRepositoryProvider).deleteWorker(workerId);
    await refresh();
    ref.invalidate(adminClientsControllerProvider);
  }
}

final adminWorkersControllerProvider =
    AsyncNotifierProvider<AdminWorkersController, List<AdminUserItem>>(
      AdminWorkersController.new,
    );

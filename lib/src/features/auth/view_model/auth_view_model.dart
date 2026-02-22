import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_api.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';

enum UserRole { provider, worker, admin }

class RegisterUserInput {
  const RegisterUserInput({
    required this.role,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.country,
    required this.postalCode,
    required this.city,
    required this.area,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.currency = 'INR',
    this.skillIds = const <int>[],
  });

  final UserRole role;
  final String name;
  final String email;
  final String phoneNumber;
  final String password;
  final String country;
  final String postalCode;
  final String city;
  final String area;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final String currency;
  final List<int> skillIds;
}

class AuthState {
  const AuthState({
    this.isHydrating = true,
    this.isLoading = false,
    this.errorMessage,
    this.email,
    this.role,
    this.token,
    this.userId,
    this.name,
    this.phoneNumber,
    this.profileImageUrl,
    this.currentAddressId,
    this.currentAddressFull,
    this.savedAddresses = const <AddressInfo>[],
    this.skillIds = const <int>[],
    this.currency = 'INR',
    this.experienceYears,
    this.certifications,
    this.isOnDuty,
    this.payoutAccount,
  });

  final bool isHydrating;
  final bool isLoading;
  final String? errorMessage;
  final String? email;
  final UserRole? role;
  final String? token;
  final int? userId;
  final String? name;
  final String? phoneNumber;
  final String? profileImageUrl;
  final int? currentAddressId;
  final AddressInfo? currentAddressFull;
  final List<AddressInfo> savedAddresses;
  final List<int> skillIds;
  final String currency;
  final int? experienceYears;
  final String? certifications;
  final bool? isOnDuty;
  final String? payoutAccount;

  bool get isAuthenticated =>
      token != null && token!.isNotEmpty && userId != null;

  AuthState copyWith({
    bool? isHydrating,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? email,
    UserRole? role,
    String? token,
    int? userId,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    int? currentAddressId,
    AddressInfo? currentAddressFull,
    List<AddressInfo>? savedAddresses,
    List<int>? skillIds,
    String? currency,
    int? experienceYears,
    String? certifications,
    bool? isOnDuty,
    String? payoutAccount,
    bool clearSession = false,
  }) {
    if (clearSession) {
      return const AuthState(isHydrating: false);
    }

    return AuthState(
      isHydrating: isHydrating ?? this.isHydrating,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      email: email ?? this.email,
      role: role ?? this.role,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      currentAddressId: currentAddressId ?? this.currentAddressId,
      currentAddressFull: currentAddressFull ?? this.currentAddressFull,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      skillIds: skillIds ?? this.skillIds,
      currency: currency ?? this.currency,
      experienceYears: experienceYears ?? this.experienceYears,
      certifications: certifications ?? this.certifications,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      payoutAccount: payoutAccount ?? this.payoutAccount,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restoreSession();
    return const AuthState();
  }

  Future<void> _restoreSession() async {
    try {
      final persisted = await ref.read(localStorageProvider).readAuthSession();
      if (persisted == null) {
        state = state.copyWith(isHydrating: false, clearError: true);
        return;
      }

      final role = _mapRole(persisted['role']?.toString() ?? '');
      final skillIdsRaw = persisted['skillIds'];
      final skillIds = <int>[];
      if (skillIdsRaw is List) {
        for (final value in skillIdsRaw) {
          final id = _asInt(value);
          if (id != null) {
            skillIds.add(id);
          }
        }
      }

      state = AuthState(
        isHydrating: false,
        isLoading: false,
        email: persisted['email']?.toString(),
        role: role,
        token: persisted['token']?.toString(),
        userId: _asInt(persisted['userId']),
        name: persisted['name']?.toString(),
        phoneNumber: persisted['phoneNumber']?.toString(),
        profileImageUrl: persisted['profileImageUrl']?.toString(),
        currentAddressId: _asInt(persisted['currentAddressId']),
        skillIds: skillIds,
        currency: persisted['currency']?.toString() ?? 'INR',
        experienceYears: _asInt(persisted['experienceYears']),
        certifications: persisted['certifications']?.toString(),
        isOnDuty: _asBool(persisted['isOnDuty']),
        payoutAccount: persisted['payoutAccount']?.toString(),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed restoring persisted auth session',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isHydrating: false,
        errorMessage: _errorMessage(error),
      );
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(
      isHydrating: false,
      isLoading: true,
      clearError: true,
    );

    try {
      final authApi = ref.read(authApiProvider);
      final loginResult = await authApi.login(email: email, password: password);
      final role = _mapRole(loginResult.role);

      UserProfileData? profile;

      if (role == UserRole.provider) {
        profile = await authApi.fetchClientProfile(loginResult.token);
      } else if (role == UserRole.worker) {
        profile = await authApi.fetchWorkerProfile(loginResult.token);
      }

      final nextState = AuthState(
        isHydrating: false,
        isLoading: false,
        email: loginResult.email,
        role: role,
        token: loginResult.token,
        userId: loginResult.userId,
        name: profile?.name,
        phoneNumber: profile?.phoneNumber,
        profileImageUrl: profile?.profileImageUrl,
        currentAddressId: profile?.currentAddressId,
        currentAddressFull: profile?.currentAddressFull,
        savedAddresses: profile?.savedAddresses ?? const <AddressInfo>[],
        skillIds: profile?.skillIds ?? const <int>[],
        currency: profile?.currency ?? 'INR',
        experienceYears: profile?.experienceYears,
        certifications: profile?.certifications,
        isOnDuty: profile?.isOnDuty,
        payoutAccount: profile?.payoutAccount,
      );
      state = nextState;
      await _persistSession(nextState);
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Login failed for $email',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isHydrating: false,
        isLoading: false,
        errorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> register(RegisterUserInput input) async {
    state = state.copyWith(
      isHydrating: false,
      isLoading: true,
      clearError: true,
    );

    try {
      final authApi = ref.read(authApiProvider);
      final request = RegistrationRequest(
        name: input.name.trim(),
        email: input.email.trim(),
        phoneNumber: input.phoneNumber.trim(),
        password: input.password,
        country: input.country.trim().toUpperCase(),
        postalCode: input.postalCode.trim(),
        city: input.city.trim(),
        area: input.area.trim(),
        fullAddress: input.fullAddress.trim(),
        latitude: input.latitude,
        longitude: input.longitude,
        currency: input.currency.trim().toUpperCase(),
        skillIds: input.skillIds,
      );

      if (input.role == UserRole.provider) {
        await authApi.registerClient(request);
      } else if (input.role == UserRole.worker) {
        await authApi.registerWorker(request);
      } else {
        throw const ApiException('Admin signup is not supported in mobile flow');
      }

      state = AuthState(
        isHydrating: false,
        isLoading: false,
        email: input.email.trim(),
        role: input.role,
        name: input.name.trim(),
        phoneNumber: input.phoneNumber.trim(),
        currency: input.currency.trim().toUpperCase(),
        skillIds: input.skillIds,
      );
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Registration failed for ${input.email}',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isHydrating: false,
        isLoading: false,
        errorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> refreshProfile() async {
    if (!state.isAuthenticated || state.token == null || state.userId == null) {
      return false;
    }

    if (state.role == UserRole.admin) {
      return true;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final authApi = ref.read(authApiProvider);
      final profile = state.role == UserRole.provider
          ? await authApi.fetchClientProfile(state.token!)
          : await authApi.fetchWorkerProfile(state.token!);

      final nextState = state.copyWith(
        isLoading: false,
        name: profile.name,
        email: profile.email ?? state.email,
        phoneNumber: profile.phoneNumber,
        profileImageUrl: profile.profileImageUrl,
        currentAddressId: profile.currentAddressId,
        currentAddressFull: profile.currentAddressFull,
        savedAddresses: profile.savedAddresses,
        skillIds: profile.skillIds,
        currency: profile.currency,
        experienceYears: profile.experienceYears,
        certifications: profile.certifications,
        isOnDuty: profile.isOnDuty,
        payoutAccount: profile.payoutAccount,
      );

      state = nextState;
      await _persistSession(nextState);
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Profile refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> updateProfile(UserProfileUpdateInput input) async {
    if (!state.isAuthenticated ||
        state.token == null ||
        state.userId == null ||
        state.role == null) {
      return false;
    }

    if (state.role == UserRole.admin) {
      state = state.copyWith(
        errorMessage: 'Admin profile updates are not supported in this flow',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final authApi = ref.read(authApiProvider);
      final updated = state.role == UserRole.provider
          ? await authApi.updateClientProfile(
              token: state.token!,
              clientId: state.userId!,
              input: input,
            )
          : await authApi.updateWorkerProfile(
              token: state.token!,
              workerId: state.userId!,
              input: input,
            );

      final nextState = state.copyWith(
        isLoading: false,
        name: updated.name ?? state.name,
        email: updated.email ?? state.email,
        phoneNumber: updated.phoneNumber ?? state.phoneNumber,
        profileImageUrl: updated.profileImageUrl ?? state.profileImageUrl,
        currentAddressId: updated.currentAddressId ?? state.currentAddressId,
        currentAddressFull: updated.currentAddressFull ?? state.currentAddressFull,
        savedAddresses: updated.savedAddresses.isNotEmpty
            ? updated.savedAddresses
            : state.savedAddresses,
        skillIds: updated.skillIds.isEmpty ? state.skillIds : updated.skillIds,
        currency: updated.currency,
        experienceYears: updated.experienceYears ?? state.experienceYears,
        certifications: updated.certifications ?? state.certifications,
        isOnDuty: updated.isOnDuty ?? state.isOnDuty,
        payoutAccount: updated.payoutAccount ?? state.payoutAccount,
      );

      state = nextState;
      await _persistSession(nextState);
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Profile update failed',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    if (!state.isAuthenticated ||
        state.token == null ||
        state.userId == null ||
        state.role == null) {
      return false;
    }

    if (state.role == UserRole.admin) {
      state = state.copyWith(
        errorMessage: 'Admin account deletion is disabled in mobile flow',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final authApi = ref.read(authApiProvider);
      if (state.role == UserRole.provider) {
        await authApi.deleteClient(token: state.token!, clientId: state.userId!);
      } else {
        await authApi.deleteWorker(token: state.token!, workerId: state.userId!);
      }

      await logout();
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Account deletion failed',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<void> setRole(UserRole role) async {
    final nextState = state.copyWith(isHydrating: false, role: role);
    state = nextState;
    if (nextState.isAuthenticated) {
      await _persistSession(nextState);
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> logout() async {
    await ref.read(localStorageProvider).clearAuthSession();
    state = const AuthState(isHydrating: false);
  }

  UserRole? _mapRole(String roleValue) {
    switch (roleValue.toUpperCase()) {
      case 'ROLE_CLIENT':
        return UserRole.provider;
      case 'ROLE_WORKER':
        return UserRole.worker;
      case 'ROLE_ADMIN':
        return UserRole.admin;
      default:
        return null;
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.userMessage;
    }
    final message = error.toString().trim();
    if (message.isEmpty || message == 'Exception') {
      return 'Unexpected error occurred. Please retry.';
    }
    return message;
  }

  Future<void> _persistSession(AuthState authState) async {
    if (!authState.isAuthenticated) {
      return;
    }

    await ref.read(localStorageProvider).saveAuthSession(<String, dynamic>{
      'email': authState.email,
      'role': _roleToWire(authState.role),
      'token': authState.token,
      'userId': authState.userId,
      'name': authState.name,
      'phoneNumber': authState.phoneNumber,
      'profileImageUrl': authState.profileImageUrl,
      'currentAddressId': authState.currentAddressId,
      'skillIds': authState.skillIds,
      'currency': authState.currency,
      'experienceYears': authState.experienceYears,
      'certifications': authState.certifications,
      'isOnDuty': authState.isOnDuty,
      'payoutAccount': authState.payoutAccount,
    });
  }

  String? _roleToWire(UserRole? role) {
    switch (role) {
      case UserRole.provider:
        return 'ROLE_CLIENT';
      case UserRole.worker:
        return 'ROLE_WORKER';
      case UserRole.admin:
        return 'ROLE_ADMIN';
      case null:
        return null;
    }
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  bool? _asBool(Object? value) {
    if (value is bool) {
      return value;
    }

    final text = value?.toString().toLowerCase();
    if (text == 'true') {
      return true;
    }
    if (text == 'false') {
      return false;
    }
    return null;
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

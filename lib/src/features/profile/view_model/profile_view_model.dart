import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/view_model/auth_view_model.dart';

// ─────────────────── Public Profile ───────────────────

class PublicProfileState {
  const PublicProfileState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
  });

  final UserProfileData? profile;
  final bool isLoading;
  final String? errorMessage;

  PublicProfileState copyWith({
    UserProfileData? profile,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PublicProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Fetch a public client profile
final publicClientProfileProvider = FutureProvider.family<UserProfileData, int>(
  (ref, clientId) async {
    final auth = ref.read(authControllerProvider);
    final authApi = ref.read(authApiProvider);
    return authApi.fetchClientById(token: auth.token ?? '', clientId: clientId);
  },
);

/// Fetch a public worker profile
final publicWorkerProfileProvider = FutureProvider.family<UserProfileData, int>(
  (ref, workerId) async {
    final auth = ref.read(authControllerProvider);
    final authApi = ref.read(authApiProvider);
    return authApi.fetchWorkerById(token: auth.token ?? '', workerId: workerId);
  },
);

// ─────────────────── Edit Profile ───────────────────

class EditProfileState {
  const EditProfileState({
    this.name = '',
    this.email = '',
    this.phoneNumber = '',
    this.profileImageUrl = '',
    this.experienceYears,
    this.certifications = '',
    this.payoutAccount = '',
    this.currency = 'INR',
    this.isOnDuty = true,
    this.isSubmitting = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  final String name;
  final String email;
  final String phoneNumber;
  final String profileImageUrl;
  final int? experienceYears;
  final String certifications;
  final String payoutAccount;
  final String currency;
  final bool isOnDuty;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isInitialized;

  EditProfileState copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    int? experienceYears,
    String? certifications,
    String? payoutAccount,
    String? currency,
    bool? isOnDuty,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    bool? isInitialized,
  }) {
    return EditProfileState(
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      experienceYears: experienceYears ?? this.experienceYears,
      certifications: certifications ?? this.certifications,
      payoutAccount: payoutAccount ?? this.payoutAccount,
      currency: currency ?? this.currency,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class EditProfileController extends Notifier<EditProfileState> {
  @override
  EditProfileState build() {
    final auth = ref.read(authControllerProvider);
    return EditProfileState(
      name: auth.name ?? '',
      email: auth.email ?? '',
      phoneNumber: auth.phoneNumber ?? '',
      profileImageUrl: auth.profileImageUrl ?? '',
      experienceYears: auth.experienceYears,
      certifications: auth.certifications ?? '',
      payoutAccount: auth.payoutAccount ?? '',
      currency: auth.currency,
      isOnDuty: auth.isOnDuty ?? true,
      isInitialized: true,
    );
  }

  void updateName(String value) =>
      state = state.copyWith(name: value, clearError: true);
  void updateEmail(String value) =>
      state = state.copyWith(email: value, clearError: true);
  void updatePhoneNumber(String value) =>
      state = state.copyWith(phoneNumber: value, clearError: true);
  void updateProfileImageUrl(String value) =>
      state = state.copyWith(profileImageUrl: value, clearError: true);
  void updateExperienceYears(int? value) =>
      state = state.copyWith(experienceYears: value, clearError: true);
  void updateCertifications(String value) =>
      state = state.copyWith(certifications: value, clearError: true);
  void updatePayoutAccount(String value) =>
      state = state.copyWith(payoutAccount: value, clearError: true);
  void toggleOnDuty() =>
      state = state.copyWith(isOnDuty: !state.isOnDuty, clearError: true);

  Future<bool> save() async {
    if (state.name.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Name is required');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final input = UserProfileUpdateInput(
        name: state.name.trim(),
        email: state.email.trim(),
        phoneNumber: state.phoneNumber.trim(),
        profileImageUrl: state.profileImageUrl.trim().isEmpty
            ? null
            : state.profileImageUrl.trim(),
        experienceYears: state.experienceYears,
        certifications: state.certifications.trim().isEmpty
            ? null
            : state.certifications.trim(),
        payoutAccount: state.payoutAccount.trim().isEmpty
            ? null
            : state.payoutAccount.trim(),
        isOnDuty: state.isOnDuty,
        currency: state.currency,
      );

      final success = await ref
          .read(authControllerProvider.notifier)
          .updateProfile(input);

      state = state.copyWith(isSubmitting: false);

      if (!success) {
        final authError = ref.read(authControllerProvider).errorMessage;
        state = state.copyWith(
          errorMessage: authError ?? 'Failed to update profile',
        );
      }

      return success;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.toString(),
      );
      return false;
    }
  }
}

final editProfileControllerProvider =
    NotifierProvider<EditProfileController, EditProfileState>(
      EditProfileController.new,
    );

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_view_model.dart';

final onboardingPageProvider = StateProvider.autoDispose<int>((ref) => 0);

final loginPasswordObscuredProvider = StateProvider.autoDispose<bool>(
  (ref) => true,
);

class RegisterFormUiState {
  const RegisterFormUiState({
    this.selectedRole = UserRole.provider,
    this.selectedCountry = 'IN',
    this.selectedCurrency = 'INR',
    this.isPasswordObscured = true,
  });

  final UserRole selectedRole;
  final String selectedCountry;
  final String selectedCurrency;
  final bool isPasswordObscured;

  RegisterFormUiState copyWith({
    UserRole? selectedRole,
    String? selectedCountry,
    String? selectedCurrency,
    bool? isPasswordObscured,
  }) {
    return RegisterFormUiState(
      selectedRole: selectedRole ?? this.selectedRole,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      isPasswordObscured: isPasswordObscured ?? this.isPasswordObscured,
    );
  }
}

class RegisterFormUiController
    extends AutoDisposeNotifier<RegisterFormUiState> {
  @override
  RegisterFormUiState build() => const RegisterFormUiState();

  void setRole(UserRole role) {
    state = state.copyWith(selectedRole: role);
  }

  void setCountry(String country) {
    state = state.copyWith(selectedCountry: country);
  }

  void setCurrency(String currency) {
    state = state.copyWith(selectedCurrency: currency);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordObscured: !state.isPasswordObscured);
  }
}

final registerFormUiProvider =
    AutoDisposeNotifierProvider<RegisterFormUiController, RegisterFormUiState>(
      RegisterFormUiController.new,
    );

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app.dart';
import '../view_model/auth_ui_view_model.dart';
import '../view_model/auth_view_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../core/widgets/primary_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _areaController = TextEditingController();
  final _fullAddressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _areaController.dispose();
    _fullAddressController.dispose();
    super.dispose();
  }

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final required = _required(value, 'Email');
    if (required != null) {
      return required;
    }

    final email = value!.trim();
    final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isEmail) {
      return 'Enter a valid email';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final required = _required(value, 'Phone number');
    if (required != null) {
      return required;
    }

    final isDigitsOnly = RegExp(r'^[+]?\d{10,15}$').hasMatch(value!.trim());
    if (!isDigitsOnly) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final required = _required(value, 'Password');
    if (required != null) {
      return required;
    }

    if (value!.length < 6) {
      return 'Minimum 6 characters';
    }

    return null;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    final registerUi = ref.read(registerFormUiProvider);

    final city = _cityController.text.trim();
    final postalCode = _postalCodeController.text.trim();
    final area = _areaController.text.trim().isEmpty
        ? city
        : _areaController.text.trim();
    final fallbackAddress = '$city, $postalCode, ${registerUi.selectedCountry}';
    final fullAddress = _fullAddressController.text.trim().isEmpty
        ? fallbackAddress
        : _fullAddressController.text.trim();

    final input = RegisterUserInput(
      role: registerUi.selectedRole,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
      country: registerUi.selectedCountry,
      postalCode: postalCode,
      city: city,
      area: area,
      fullAddress: fullAddress,
      latitude: 28.6139,
      longitude: 77.2090,
      currency: registerUi.selectedCurrency,
      skillIds: registerUi.selectedRole == UserRole.worker
          ? const <int>[1]
          : const <int>[],
    );

    final success = await ref
        .read(authControllerProvider.notifier)
        .register(input);

    if (!mounted) {
      return;
    }

    final authState = ref.read(authControllerProvider);
    if (!success) {
      final error = authState.errorMessage ?? 'Unable to register';
      AppNotifier.showError(context, error);
      return;
    }

    AppNotifier.showSuccess(context, 'Registration successful. Please log in.');

    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final registerUi = ref.watch(registerFormUiProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Account',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 30),
                ),
                const SizedBox(height: 8),
                Text(
                  'Register as provider or worker with your basic location profile.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Role',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Job Provider'),
                              selected:
                                  registerUi.selectedRole == UserRole.provider,
                              onSelected: authState.isLoading
                                  ? null
                                  : (_) {
                                      ref
                                          .read(registerFormUiProvider.notifier)
                                          .setRole(UserRole.provider);
                                    },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Job Worker'),
                              selected:
                                  registerUi.selectedRole == UserRole.worker,
                              onSelected: authState.isLoading
                                  ? null
                                  : (_) {
                                      ref
                                          .read(registerFormUiProvider.notifier)
                                          .setRole(UserRole.worker);
                                    },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          validator: (value) => _required(value, 'Name'),
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: _validatePhone,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            prefixIcon: Icon(Icons.call_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: registerUi.isPasswordObscured,
                          textInputAction: TextInputAction.next,
                          validator: _validatePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () {
                                ref
                                    .read(registerFormUiProvider.notifier)
                                    .togglePasswordVisibility();
                              },
                              icon: Icon(
                                registerUi.isPasswordObscured
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: registerUi.selectedCountry,
                                decoration: const InputDecoration(
                                  labelText: 'Country',
                                  prefixIcon: Icon(Icons.flag_outlined),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'IN',
                                    child: Text('IN'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'US',
                                    child: Text('US'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'GB',
                                    child: Text('GB'),
                                  ),
                                ],
                                onChanged: authState.isLoading
                                    ? null
                                    : (value) {
                                        if (value == null) {
                                          return;
                                        }
                                        ref
                                            .read(
                                              registerFormUiProvider.notifier,
                                            )
                                            .setCountry(value);
                                      },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: registerUi.selectedCurrency,
                                decoration: const InputDecoration(
                                  labelText: 'Currency',
                                  prefixIcon: Icon(
                                    Icons.currency_exchange_outlined,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'INR',
                                    child: Text('INR'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'USD',
                                    child: Text('USD'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'EUR',
                                    child: Text('EUR'),
                                  ),
                                ],
                                onChanged: authState.isLoading
                                    ? null
                                    : (value) {
                                        if (value == null) {
                                          return;
                                        }
                                        ref
                                            .read(
                                              registerFormUiProvider.notifier,
                                            )
                                            .setCurrency(value);
                                      },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cityController,
                          textInputAction: TextInputAction.next,
                          validator: (value) => _required(value, 'City'),
                          decoration: const InputDecoration(
                            labelText: 'City',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _postalCodeController,
                          textInputAction: TextInputAction.next,
                          validator: (value) => _required(value, 'Postal code'),
                          decoration: const InputDecoration(
                            labelText: 'Postal code',
                            prefixIcon: Icon(Icons.local_post_office_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _areaController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Area (optional)',
                            prefixIcon: Icon(Icons.pin_drop_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _fullAddressController,
                          textInputAction: TextInputAction.done,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Full address (optional)',
                            prefixIcon: Icon(Icons.home_work_outlined),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Register',
                          isLoading: authState.isLoading,
                          onPressed: authState.isLoading ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ),
                if (authState.errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppPalette.danger.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Text(
                      authState.errorMessage!,
                      style: const TextStyle(
                        color: AppPalette.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already registered?'),
                    TextButton(
                      onPressed: authState.isLoading
                          ? null
                          : () {
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.login,
                              );
                            },
                      child: const Text('Log in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

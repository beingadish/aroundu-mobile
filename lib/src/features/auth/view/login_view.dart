import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app.dart';
import '../view_model/auth_ui_view_model.dart';
import '../view_model/auth_view_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../core/widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final email = value.trim();
    final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isEmail) {
      return 'Enter a valid email';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Minimum 6 characters';
    }
    return null;
  }

  void _routeAfterAuth(AuthState authState) {
    if (!mounted) {
      return;
    }

    if (authState.role == UserRole.admin) {
      Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
      return;
    }

    if (authState.role == UserRole.provider) {
      Navigator.pushReplacementNamed(context, AppRoutes.providerHome);
      return;
    }

    if (authState.role == UserRole.worker) {
      Navigator.pushReplacementNamed(context, AppRoutes.workerHome);
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.role);
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) {
      return;
    }

    final authState = ref.read(authControllerProvider);
    if (success) {
      _routeAfterAuth(authState);
      return;
    }

    final error = authState.errorMessage ?? 'Unable to login. Please retry.';
    AppNotifier.showError(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final obscurePassword = ref.watch(loginPasswordObscuredProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Welcome Back',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 30),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue as provider or worker.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
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
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: obscurePassword,
                          textInputAction: TextInputAction.done,
                          validator: _validatePassword,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () {
                                ref
                                        .read(
                                          loginPasswordObscuredProvider
                                              .notifier,
                                        )
                                        .state =
                                    !obscurePassword;
                              },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        PrimaryButton(
                          label: 'Log In',
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
                    const Text('No account yet?'),
                    TextButton(
                      onPressed: authState.isLoading
                          ? null
                          : () {
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.register,
                              );
                            },
                      child: const Text('Create one'),
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

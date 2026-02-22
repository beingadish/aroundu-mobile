import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/core/theme/app_theme.dart';
import 'src/core/view_model/theme_view_model.dart';
import 'src/features/auth/view/login_view.dart';
import 'src/features/auth/view/onboarding_view.dart';
import 'src/features/auth/view/register_view.dart';
import 'src/features/auth/view/role_selection_view.dart';
import 'src/features/auth/view/splash_view.dart';
import 'src/features/chat/view/conversations_view.dart';
import 'src/features/profile/view/profile_view.dart';
import 'src/features/profile/view/edit_profile_view.dart';
import 'src/features/jobs/view/provider_shell_view.dart';
import 'src/features/jobs/view/worker_shell_view.dart';
import 'src/features/jobs/view/admin_shell_view.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String role = '/role';
  static const String providerHome = '/provider';
  static const String workerHome = '/worker';
  static const String adminHome = '/admin';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String conversations = '/conversations';
}

class AroundUApp extends ConsumerWidget {
  const AroundUApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAroundUTheme(),
      darkTheme: buildAroundUDarkTheme(),
      themeMode: themeMode,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.onboarding: (_) => const OnboardingScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.role: (_) => const RoleSelectionScreen(),
        AppRoutes.providerHome: (_) => const ProviderShellScreen(),
        AppRoutes.workerHome: (_) => const WorkerShellScreen(),
        AppRoutes.adminHome: (_) => const AdminShellScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.editProfile: (_) => const EditProfileScreen(),
        AppRoutes.conversations: (_) => const ConversationsScreen(),
      },
    );
  }
}

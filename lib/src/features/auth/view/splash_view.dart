import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app.dart';
import '../view_model/auth_view_model.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), _routeToNextScreen);
  }

  void _routeToNextScreen() {
    if (!mounted) {
      return;
    }

    final authState = ref.read(authControllerProvider);
    if (authState.isHydrating) {
      _timer = Timer(const Duration(milliseconds: 300), _routeToNextScreen);
      return;
    }

    if (!authState.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      return;
    }

    if (authState.role == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.role);
      return;
    }

    final destination = switch (authState.role) {
      UserRole.provider => AppRoutes.providerHome,
      UserRole.worker => AppRoutes.workerHome,
      UserRole.admin => AppRoutes.adminHome,
      null => AppRoutes.role,
    };

    Navigator.pushReplacementNamed(context, destination);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/MainLogoWhite.png',
              width: 190,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.workspaces_rounded,
                color: Colors.white,
                size: 96,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.8,
            ),
          ],
        ),
      ),
    );
  }
}

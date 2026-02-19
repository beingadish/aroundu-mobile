import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app.dart';
import '../view_model/auth_view_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  @override
  void initState() {
    super.initState();
    _guardAuthenticatedAccess();
  }

  void _guardAuthenticatedAccess() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authControllerProvider);
      if (!mounted) {
        return;
      }

      if (authState.isHydrating) {
        _guardAuthenticatedAccess();
        return;
      }

      if (authState.isAuthenticated) {
        if (authState.role == UserRole.admin) {
          Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
        }
        return;
      }

      Navigator.pushReplacementNamed(context, AppRoutes.login);
    });
  }

  Future<void> _continue() async {
    final role = ref.read(authControllerProvider).role;
    if (role == null) {
      return;
    }

    if (role == UserRole.admin) {
      Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
      return;
    }

    await ref.read(authControllerProvider.notifier).setRole(role);
    if (!mounted) {
      return;
    }
    final destination = role == UserRole.provider
        ? AppRoutes.providerHome
        : AppRoutes.workerHome;

    Navigator.pushReplacementNamed(context, destination);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final selectedRole = authState.role;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Your Role',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 30),
              ),
              const SizedBox(height: 8),
              Text(
                authState.email == null
                    ? 'Select the workflow you want to use in AroundU.'
                    : 'Signed in as ${authState.email}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              _RoleCard(
                title: 'Job Provider',
                subtitle: 'Post jobs and manage incoming bids.',
                icon: Icons.business_center_outlined,
                selected: selectedRole == UserRole.provider,
                onTap: () {
                  ref
                      .read(authControllerProvider.notifier)
                      .setRole(UserRole.provider);
                },
              ),
              const SizedBox(height: 12),
              _RoleCard(
                title: 'Job Worker',
                subtitle: 'Browse nearby jobs and place bids quickly.',
                icon: Icons.build_circle_outlined,
                selected: selectedRole == UserRole.worker,
                onTap: () {
                  ref
                      .read(authControllerProvider.notifier)
                      .setRole(UserRole.worker);
                },
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Continue',
                onPressed: selectedRole == null ? null : _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppPalette.primary : AppPalette.border,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? AppPalette.primary.withValues(alpha: 0.08)
              : AppPalette.surface,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? AppPalette.primary.withValues(alpha: 0.16)
                    : AppPalette.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? AppPalette.primary : AppPalette.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

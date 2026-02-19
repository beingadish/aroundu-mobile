import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app.dart';
import '../../auth/view_model/admin_view_model.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/view_model/theme_view_model.dart';
import '../../../core/widgets/app_notification.dart';
import '../view_model/navigation_view_model.dart';

class AdminShellScreen extends ConsumerWidget {
  const AdminShellScreen({super.key});

  static const List<String> _titles = ['Clients', 'Workers', 'Admin'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(adminTabIndexProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_titles[tabIndex])),
      body: IndexedStack(
        index: tabIndex,
        children: const [
          _AdminUsersTab(role: UserRole.provider),
          _AdminUsersTab(role: UserRole.worker),
          _AdminAccountTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (index) {
          ref.read(adminTabIndexProvider.notifier).setIndex(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Clients',
          ),
          NavigationDestination(
            icon: Icon(Icons.engineering_outlined),
            selectedIcon: Icon(Icons.engineering_rounded),
            label: 'Workers',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

class _AdminUsersTab extends ConsumerWidget {
  const _AdminUsersTab({required this.role});

  final UserRole role;

  Future<void> _refresh(WidgetRef ref) {
    if (role == UserRole.provider) {
      return ref.read(adminClientsControllerProvider.notifier).refresh();
    }

    return ref.read(adminWorkersControllerProvider.notifier).refresh();
  }

  Future<void> _deleteUser(
    BuildContext context,
    WidgetRef ref,
    AdminUserItem user,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete ${role == UserRole.provider ? 'client' : 'worker'}'),
          content: Text(
            'This action removes ${user.name} (${user.email}) permanently. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppPalette.danger),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      if (role == UserRole.provider) {
        await ref
            .read(adminClientsControllerProvider.notifier)
            .deleteClient(user.id);
      } else {
        await ref
            .read(adminWorkersControllerProvider.notifier)
            .deleteWorker(user.id);
      }

      if (context.mounted) {
        AppNotifier.showSuccess(context, 'User deleted successfully');
      }
    } catch (error) {
      if (context.mounted) {
        AppNotifier.showError(context, error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = role == UserRole.provider
        ? ref.watch(adminClientsControllerProvider)
        : ref.watch(adminWorkersControllerProvider);

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 120),
            Icon(
              Icons.cloud_off_rounded,
              color: AppPalette.textSecondary,
              size: 46,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load users',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _refresh(ref),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
        data: (users) {
          if (users.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 100),
                Image.asset(
                  'assets/images/ProviderEmptyScreen.png',
                  height: 150,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 14),
                Text(
                  role == UserRole.provider
                      ? 'No clients found'
                      : 'No workers found',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Pull down to refresh this list.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = users[index];

              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 220 + (index * 30)),
                tween: Tween<double>(begin: 0, end: 1),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 14 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppPalette.primary.withValues(alpha: 0.12),
                      child: Text(
                        user.name.isEmpty
                            ? '?'
                            : user.name.characters.first.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppPalette.primary,
                        ),
                      ),
                    ),
                    title: Text(user.name),
                    subtitle: Text('${user.email}\n${user.phoneNumber}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      tooltip: 'Delete user',
                      onPressed: () => _deleteUser(context, ref, user),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppPalette.danger,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminAccountTab extends ConsumerWidget {
  const _AdminAccountTab();

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    await ref.read(adminTabIndexProvider.notifier).reset();
    await ref.read(workerTabIndexProvider.notifier).reset();
    await ref.read(providerTabIndexProvider.notifier).reset();

    if (!context.mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Session', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text(authState.email ?? 'Unknown',
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 6),
                Text(
                  'Manage users from the Clients and Workers tabs.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Switch between light and dark themes'),
            value: isDarkMode,
            onChanged: (enabled) {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
            },
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _logout(context, ref),
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.danger,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Logout'),
        ),
      ],
    );
  }
}

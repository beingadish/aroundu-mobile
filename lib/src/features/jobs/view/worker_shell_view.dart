import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/view_model/theme_view_model.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../core/widgets/primary_button.dart';
import '../model/job_item.dart';
import '../model/job_workflow_models.dart';
import '../view_model/job_view_model.dart';
import '../view_model/navigation_view_model.dart';
import '../view_model/worker_skills_view_model.dart';
import 'widgets/job_card.dart';
import 'widgets/job_shared_widgets.dart';

class WorkerShellScreen extends ConsumerWidget {
  const WorkerShellScreen({super.key});

  static const List<String> _titles = ['Nearby Jobs', 'Skills', 'Account'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(workerTabIndexProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_titles[tabIndex])),
      body: IndexedStack(
        index: tabIndex,
        children: const [
          _WorkerFeedTab(),
          _WorkerSkillsTab(),
          _WorkerAccountTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (index) {
          ref.read(workerTabIndexProvider.notifier).setIndex(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.location_searching_outlined),
            selectedIcon: Icon(Icons.location_searching_rounded),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman_rounded),
            label: 'Skills',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

class _WorkerFeedTab extends ConsumerWidget {
  const _WorkerFeedTab();

  Future<void> _refresh(WidgetRef ref) {
    return ref.read(workerFeedControllerProvider.notifier).refresh();
  }

  Future<void> _openWorkflowSheet(BuildContext context, JobItem job) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        maxChildSize: 0.96,
        minChildSize: 0.7,
        builder: (_, controller) {
          return _WorkerJobWorkflowSheet(
            jobId: job.jobId,
            scrollController: controller,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(workerFeedControllerProvider);

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: feedAsync.when(
        loading: () => const CenteredListBody(
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
        error: (error, _) => CenteredListBody(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Unable to load worker feed',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
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
        ),
        data: (jobs) {
          if (jobs.isEmpty) {
            return CenteredListBody(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/ComingSoon.png',
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No nearby jobs right now',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pull down to refresh and check again.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final job = jobs[index];
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 200 + (index * 35)),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: JobCard(
                  job: job,
                  showDistance: true,
                  onTap: () => _openWorkflowSheet(context, job),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WorkerSkillsTab extends ConsumerWidget {
  const _WorkerSkillsTab();

  static const List<String> _skills = [
    'Electrical',
    'Plumbing',
    'Carpentry',
    'Painting',
    'Cleaning',
    'Mechanic',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSkills = ref.watch(workerSkillsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Your Skills', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'These skills are saved locally for fast feed filtering.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _skills.map((skill) {
            final active = selectedSkills.contains(skill);

            return FilterChip(
              label: Text(skill),
              selected: active,
              onSelected: (selected) {
                ref
                    .read(workerSkillsProvider.notifier)
                    .toggleSkill(skill, selected);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              selectedSkills.isEmpty
                  ? 'No skills selected. Add at least one to get relevant jobs.'
                  : 'Selected ${selectedSkills.length} skill(s): ${selectedSkills.join(', ')}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkerAccountTab extends ConsumerWidget {
  const _WorkerAccountTab();

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    await ref.read(workerTabIndexProvider.notifier).reset();
    await ref.read(providerTabIndexProvider.notifier).reset();
    await ref.read(adminTabIndexProvider.notifier).reset();

    if (!context.mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<void> _openProfileEditor(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authControllerProvider);
    final nameController = TextEditingController(text: authState.name ?? '');
    final emailController = TextEditingController(text: authState.email ?? '');
    final phoneController = TextEditingController(
      text: authState.phoneNumber ?? '',
    );
    final imageController = TextEditingController(
      text: authState.profileImageUrl ?? '',
    );
    final experienceController = TextEditingController(
      text: authState.experienceYears?.toString() ?? '',
    );
    final certController = TextEditingController(
      text: authState.certifications ?? '',
    );
    final payoutController = TextEditingController(
      text: authState.payoutAccount ?? '',
    );

    bool isOnDuty = authState.isOnDuty ?? true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Update Worker Profile',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.call_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: imageController,
                      decoration: const InputDecoration(
                        labelText: 'Profile image URL',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: experienceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Experience (years)',
                        prefixIcon: Icon(Icons.timeline_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: certController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Certifications',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: payoutController,
                      decoration: const InputDecoration(
                        labelText: 'Payout account',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      value: isOnDuty,
                      onChanged: (value) {
                        setModalState(() {
                          isOnDuty = value;
                        });
                      },
                      title: const Text('On duty'),
                      subtitle: const Text('Enable to receive job opportunities'),
                    ),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      label: 'Save Changes',
                      onPressed: () async {
                        final success = await ref
                            .read(authControllerProvider.notifier)
                            .updateProfile(
                              UserProfileUpdateInput(
                                name: nameController.text,
                                email: emailController.text,
                                phoneNumber: phoneController.text,
                                profileImageUrl: imageController.text,
                                experienceYears:
                                    int.tryParse(experienceController.text),
                                certifications: certController.text,
                                isOnDuty: isOnDuty,
                                payoutAccount: payoutController.text,
                              ),
                            );

                        if (!context.mounted) {
                          return;
                        }

                        if (success) {
                          Navigator.pop(context);
                          AppNotifier.showSuccess(context, 'Profile updated');
                        } else {
                          final error =
                              ref.read(authControllerProvider).errorMessage ??
                              'Failed to update profile';
                          AppNotifier.showError(context, error);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    imageController.dispose();
    experienceController.dispose();
    certController.dispose();
    payoutController.dispose();
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: const Text(
            'This permanently removes your worker account and history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: AppPalette.danger),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).deleteAccount();

    if (!context.mounted) {
      return;
    }

    if (success) {
      AppNotifier.showSuccess(context, 'Account deleted');
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
      return;
    }

    final error =
        ref.read(authControllerProvider).errorMessage ??
        'Unable to delete account';
    AppNotifier.showError(context, error);
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
                Text('Account', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                AccountDetailRow(
                  label: 'Name',
                  value: authState.name ?? 'Not available',
                ),
                const SizedBox(height: 6),
                AccountDetailRow(
                  label: 'Email',
                  value: authState.email ?? 'Not available',
                ),
                const SizedBox(height: 6),
                AccountDetailRow(
                  label: 'Role',
                  value: 'Job Worker',
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
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Profile update'),
                subtitle: const Text('Update profile and public bio'),
                onTap: () => _openProfileEditor(context, ref),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.sync_rounded),
                title: const Text('Refresh profile'),
                subtitle: const Text('Sync latest profile data from server'),
                onTap: () async {
                  final success = await ref
                      .read(authControllerProvider.notifier)
                      .refreshProfile();

                  if (!context.mounted) {
                    return;
                  }

                  if (success) {
                    AppNotifier.showSuccess(context, 'Profile synced');
                  } else {
                    final error =
                        ref.read(authControllerProvider).errorMessage ??
                        'Unable to refresh profile';
                    AppNotifier.showError(context, error);
                  }
                },
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.support_agent_rounded),
                title: Text('Help center'),
                subtitle: Text('Support and account assistance'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _deleteAccount(context, ref),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppPalette.danger,
            minimumSize: const Size.fromHeight(46),
            side: const BorderSide(color: AppPalette.danger),
          ),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Delete account'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () async => _logout(context, ref),
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

class _WorkerJobWorkflowSheet extends ConsumerStatefulWidget {
  const _WorkerJobWorkflowSheet({
    required this.jobId,
    required this.scrollController,
  });

  final int jobId;
  final ScrollController scrollController;

  @override
  ConsumerState<_WorkerJobWorkflowSheet> createState() =>
      _WorkerJobWorkflowSheetState();
}

class _WorkerJobWorkflowSheetState extends ConsumerState<_WorkerJobWorkflowSheet> {
  JobItem? _job;
  List<BidItem> _bids = const <BidItem>[];
  bool _loading = true;
  bool _working = false;
  String? _error;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _partnerNameController = TextEditingController();
  final TextEditingController _partnerFeeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _startCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _partnerNameController.dispose();
    _partnerFeeController.dispose();
    _notesController.dispose();
    _startCodeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(jobRepositoryProvider);
      final detail = await repo.fetchJobForCurrentRole(widget.jobId);
      final bids = await repo.fetchBids(widget.jobId);

      if (!mounted) {
        return;
      }

      setState(() {
        _job = detail;
        _bids = bids;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    String? successMessage,
    bool reload = true,
  }) async {
    setState(() {
      _working = true;
    });

    try {
      await action();
      if (!mounted) {
        return;
      }

      if (successMessage != null && successMessage.isNotEmpty) {
        AppNotifier.showSuccess(context, successMessage);
      }

      if (reload) {
        await _load();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppNotifier.showError(context, error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _placeBid() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      AppNotifier.showWarning(context, 'Enter a valid bid amount');
      return Future<void>.value();
    }

    return _runAction(() async {
      await ref.read(jobRepositoryProvider).placeBid(
        PlaceBidInput(
          jobId: widget.jobId,
          amount: amount,
          partnerName: _partnerNameController.text,
          partnerFee: double.tryParse(_partnerFeeController.text.trim()),
          notes: _notesController.text,
        ),
      );
    }, successMessage: 'Bid submitted successfully');
  }

  Future<void> _respondHandshake(bool accepted, int bidId) {
    return _runAction(() async {
      await ref
          .read(jobRepositoryProvider)
          .handshakeBid(bidId: bidId, accepted: accepted);
    }, successMessage: accepted ? 'Handshake accepted' : 'Handshake declined');
  }

  Future<void> _verifyStartCode() {
    final code = _startCodeController.text.trim();
    if (code.isEmpty) {
      AppNotifier.showWarning(context, 'Enter start code first');
      return Future<void>.value();
    }

    return _runAction(() async {
      await ref
          .read(jobRepositoryProvider)
          .verifyStartCode(jobId: widget.jobId, code: code);
    }, successMessage: 'Start code verified. Job is now in progress.');
  }

  BidItem? _myBid(AuthState authState) {
    final workerId = authState.userId;
    if (workerId == null) {
      return null;
    }

    for (final bid in _bids) {
      if (bid.workerId == workerId) {
        return bid;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _job == null) {
      return ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 120),
          Text(
            'Unable to load job workflow',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    final job = _job!;
    final statusCode = job.statusCode.toUpperCase();
    final myBid = _myBid(authState);
    final canPlaceBid = statusCode == 'OPEN_FOR_BIDS' && myBid == null;
    final canHandshake =
        myBid != null &&
        myBid.status.toUpperCase() == 'SELECTED' &&
        statusCode == 'BID_SELECTED_AWAITING_HANDSHAKE';
    final canVerifyStart = statusCode == 'READY_TO_START';

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(job.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(job.description, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            MetaPill(label: 'Status: ${job.status.label}'),
            MetaPill(label: 'Budget: ${job.budget.toStringAsFixed(0)}'),
            MetaPill(label: 'Location: ${job.location}'),
            if (job.distanceKm != null)
              MetaPill(label: 'Distance: ${job.distanceKm!.toStringAsFixed(1)} km'),
          ],
        ),
        const SizedBox(height: 14),
        if (_working) const LinearProgressIndicator(minHeight: 2.4),
        if (myBid != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Bid', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Amount: ${myBid.bidAmount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${myBid.status}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (myBid.notes != null && myBid.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(myBid.notes!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (canPlaceBid) ...[
          Text('Place Bid', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Bid amount',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _partnerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Partner name (optional)',
                      prefixIcon: Icon(Icons.group_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _partnerFeeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Partner fee (optional)',
                      prefixIcon: Icon(Icons.paid_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Submit Bid',
                    onPressed: _working ? null : _placeBid,
                  ),
                ],
              ),
            ),
          ),
        ],
        if (canHandshake && myBid != null) ...[
          Text('Client selected your bid',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _working
                      ? null
                      : () => _respondHandshake(true, myBid.id),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Accept'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _working
                      ? null
                      : () => _respondHandshake(false, myBid.id),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Decline'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (canVerifyStart) ...[
          Text('Verify Start Code', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _startCodeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Start code',
              prefixIcon: Icon(Icons.key_rounded),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _working ? null : _verifyStartCode,
            icon: const Icon(Icons.verified_rounded),
            label: const Text('Verify & Start Work'),
          ),
        ],
        if (statusCode == 'IN_PROGRESS') ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Work is in progress. Wait for the client to verify release code and complete payment.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

void _showJobPreviewSheet(BuildContext context, JobItem job) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(job.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text(
                job.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  MetaPill(label: 'Category: ${job.category}'),
                  MetaPill(label: 'Location: ${job.location}'),
                  MetaPill(label: 'Budget: ₹${job.budget.toStringAsFixed(0)}'),
                  if (job.distanceKm != null)
                    MetaPill(
                      label:
                          'Distance: ${job.distanceKm!.toStringAsFixed(1)} km',
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
import '../view_model/create_job_form_view_model.dart';
import '../view_model/job_view_model.dart';
import '../view_model/navigation_view_model.dart';
import 'widgets/job_card.dart';
import 'widgets/job_shared_widgets.dart';

class ProviderShellScreen extends ConsumerWidget {
  const ProviderShellScreen({super.key});

  static const List<String> _titles = ['My Jobs', 'Post Job', 'Account'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(providerTabIndexProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_titles[tabIndex])),
      body: IndexedStack(
        index: tabIndex,
        children: const [
          _ProviderJobsTab(),
          _CreateJobTab(),
          _ProviderAccountTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (index) {
          ref.read(providerTabIndexProvider.notifier).setIndex(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Create',
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

class _ProviderJobsTab extends ConsumerWidget {
  const _ProviderJobsTab();

  Future<void> _refresh(WidgetRef ref) {
    return ref.read(providerJobsControllerProvider.notifier).refresh();
  }

  Future<void> _openWorkflowSheet(
    BuildContext context,
    JobItem job,
  ) async {
    await showModalBottomSheet<bool>(
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
          return _ProviderJobWorkflowSheet(
            jobId: job.jobId,
            scrollController: controller,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(providerJobsControllerProvider);

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: jobsAsync.when(
        loading: () => const CenteredListBody(
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
        error: (error, _) => CenteredListBody(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Unable to load jobs',
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
                    'assets/images/ProviderEmptyScreen.png',
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No jobs posted yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create your first job from the Post Job tab.',
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
                duration: Duration(milliseconds: 220 + (index * 40)),
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

class _CreateJobTab extends ConsumerStatefulWidget {
  const _CreateJobTab();

  @override
  ConsumerState<_CreateJobTab> createState() => _CreateJobTabState();
}

class _CreateJobTabState extends ConsumerState<_CreateJobTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();

  final List<String> _categories = const [
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Painting',
    'Cleaning',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    final selectedCategory = ref.read(createJobSelectedCategoryProvider);

    final budget = double.tryParse(_budgetController.text.trim());
    if (budget == null || budget <= 0) {
      AppNotifier.showWarning(context, 'Enter a valid budget amount');
      return;
    }

    final input = NewJobInput(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: selectedCategory,
      budget: budget,
    );

    final success = await ref
        .read(createJobControllerProvider.notifier)
        .submit(input);

    if (!mounted) {
      return;
    }

    if (success) {
      _titleController.clear();
      _descriptionController.clear();
      _budgetController.clear();
      ref.read(createJobSelectedCategoryProvider.notifier).state =
          _categories.first;

      AppNotifier.showSuccess(context, 'Job posted successfully');

      ref.read(providerTabIndexProvider.notifier).setIndex(0);
      return;
    }

    final message = _submitErrorMessage(
      ref.read(createJobControllerProvider).error,
    );
    AppNotifier.showError(context, message);
  }

  String _submitErrorMessage(Object? error) {
    if (error is ApiException) {
      return error.userMessage;
    }

    final message = error?.toString().trim();
    if (message == null || message.isEmpty) {
      return 'Failed to post job. Please retry.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(createJobControllerProvider);
    final isSubmitting = submitState.isLoading;
    final selectedCategory = ref.watch(createJobSelectedCategoryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Post a New Job',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Add clear details so workers can bid accurately.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        validator: (value) => _required(value, 'Title'),
                        decoration: const InputDecoration(
                          labelText: 'Job title',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: _categories
                            .map(
                              (category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }
                                ref
                                        .read(
                                          createJobSelectedCategoryProvider
                                              .notifier,
                                        )
                                        .state =
                                    value;
                              },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _budgetController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) => _required(value, 'Budget'),
                        decoration: const InputDecoration(
                          labelText: 'Budget',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        validator: (value) => _required(value, 'Description'),
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Job location will be taken from your provider profile.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Post Job',
                        isLoading: isSubmitting,
                        onPressed: _submit,
                      ),
                      if (submitState.hasError) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${submitState.error}',
                          style: const TextStyle(color: AppPalette.danger),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderAccountTab extends ConsumerWidget {
  const _ProviderAccountTab();

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    await ref.read(providerTabIndexProvider.notifier).reset();
    await ref.read(workerTabIndexProvider.notifier).reset();
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

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Update Profile', style: Theme.of(context).textTheme.titleLarge),
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
              const SizedBox(height: 14),
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
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    imageController.dispose();
  }

  Future<void> _openPastJobsSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        builder: (context, controller) {
          final pastJobsAsync = ref.watch(providerPastJobsControllerProvider);

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(providerPastJobsControllerProvider.notifier).refresh(),
            child: pastJobsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ListView(
                controller: controller,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 120),
                  Text(
                    'Unable to load past jobs',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return ListView(
                    controller: controller,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 120),
                      Text(
                        'No completed or cancelled jobs yet',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  controller: controller,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: jobs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => JobCard(job: jobs[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: const Text(
            'This permanently removes your provider account and related data.',
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
                  label: 'Phone',
                  value: authState.phoneNumber ?? 'Not available',
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
                subtitle: const Text('Edit your public details and preferences'),
                onTap: () => _openProfileEditor(context, ref),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('Job history'),
                subtitle: const Text('Closed and completed jobs'),
                onTap: () => _openPastJobsSheet(context, ref),
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

class _ProviderJobWorkflowSheet extends ConsumerStatefulWidget {
  const _ProviderJobWorkflowSheet({
    required this.jobId,
    required this.scrollController,
  });

  final int jobId;
  final ScrollController scrollController;

  @override
  ConsumerState<_ProviderJobWorkflowSheet> createState() =>
      _ProviderJobWorkflowSheetState();
}

class _ProviderJobWorkflowSheetState
    extends ConsumerState<_ProviderJobWorkflowSheet> {
  JobItem? _job;
  List<BidItem> _bids = const <BidItem>[];
  JobCodeInfo? _codeInfo;
  PaymentInfo? _paymentInfo;
  bool _loading = true;
  bool _working = false;
  String? _error;

  final TextEditingController _releaseCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _releaseCodeController.dispose();
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

  Future<void> _acceptBid(BidItem bid) {
    return _runAction(() async {
      await ref.read(jobRepositoryProvider).acceptBid(bid.id);
    }, successMessage: 'Bid accepted');
  }

  Future<void> _generateCodes() {
    return _runAction(() async {
      final result = await ref.read(jobRepositoryProvider).generateCodes(
        widget.jobId,
      );
      _codeInfo = result;
    }, successMessage: 'Job codes generated');
  }

  Future<void> _lockEscrow() {
    final job = _job;
    if (job == null) {
      return Future<void>.value();
    }

    return _runAction(() async {
      _paymentInfo = await ref.read(jobRepositoryProvider).lockEscrow(
        jobId: widget.jobId,
        amount: job.budget,
      );
    }, successMessage: 'Escrow locked successfully');
  }

  Future<void> _verifyReleaseAndPay() {
    final code = _releaseCodeController.text.trim();
    if (code.isEmpty) {
      AppNotifier.showWarning(context, 'Enter release code first');
      return Future<void>.value();
    }

    return _runAction(() async {
      _codeInfo = await ref.read(jobRepositoryProvider).verifyReleaseCode(
        jobId: widget.jobId,
        code: code,
      );
      _paymentInfo = await ref.read(jobRepositoryProvider).releaseEscrow(
        jobId: widget.jobId,
        releaseCode: code,
      );
    }, successMessage: 'Release verified and payment released');
  }

  Future<void> _cancelJob() {
    return _runAction(() async {
      _job = await ref.read(jobRepositoryProvider).updateJobStatus(
        jobId: widget.jobId,
        newStatus: 'CANCELLED',
      );
    }, successMessage: 'Job cancelled', reload: true);
  }

  Future<void> _deleteJob() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete job?'),
          content: const Text(
            'This will remove the job and all associated bidding activity.',
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

    await _runAction(() async {
      await ref.read(jobRepositoryProvider).deleteJob(widget.jobId);
    }, successMessage: 'Job deleted', reload: false);

    if (!mounted) {
      return;
    }

    ref.invalidate(providerJobsControllerProvider);
    ref.invalidate(providerPastJobsControllerProvider);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
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
    final canGenerateCodes =
        statusCode == 'BID_SELECTED_AWAITING_HANDSHAKE' ||
        statusCode == 'READY_TO_START';
    final canCancel = statusCode != 'COMPLETED' && statusCode != 'CANCELLED';
    final canRelease = statusCode == 'IN_PROGRESS';
    final escrowMode = (job.paymentMode ?? '').toUpperCase() == 'ESCROW';
    final canLockEscrow = statusCode == 'READY_TO_START' && escrowMode;

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
            MetaPill(label: 'ID: ${job.id}'),
            MetaPill(label: 'Status: ${job.status.label}'),
            MetaPill(label: 'Budget: ${job.budget.toStringAsFixed(0)}'),
            MetaPill(label: 'Location: ${job.location}'),
            if (job.requiredSkillNames.isNotEmpty)
              MetaPill(label: 'Skills: ${job.requiredSkillNames.join(', ')}'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.price_check_rounded, size: 18),
            const SizedBox(width: 6),
            Text('Bids', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        if (_bids.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'No bids received yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          ..._bids.map((bid) {
            final status = bid.status.toUpperCase();
            final canAcceptBid =
                statusCode == 'OPEN_FOR_BIDS' && status == 'PENDING';

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Worker #${bid.workerId}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: status == 'SELECTED'
                                ? AppPalette.success.withValues(alpha: 0.14)
                                : AppPalette.background,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            status,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bid: ${bid.bidAmount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (bid.notes != null && bid.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        bid.notes!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (canAcceptBid) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _working ? null : () => _acceptBid(bid),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Accept Bid'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 14),
        if (_working) const LinearProgressIndicator(minHeight: 2.4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Column(
            key: ValueKey<String>(statusCode),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (canGenerateCodes) ...[
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Generate Start Code',
                  onPressed: _working ? null : _generateCodes,
                ),
              ],
              if (_codeInfo?.startCode != null) ...[
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.password_rounded),
                    title: const Text('Start Code'),
                    subtitle: Text(
                      _codeInfo!.startCode!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        fontSize: 18,
                      ),
                    ),
                    trailing: IconButton(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: _codeInfo!.startCode!),
                        );
                        if (mounted) {
                          AppNotifier.showInfo(context, 'Start code copied');
                        }
                      },
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ),
                ),
              ],
              if (canLockEscrow) ...[
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _working ? null : _lockEscrow,
                  icon: const Icon(Icons.lock_rounded),
                  label: Text(
                    'Lock Escrow (${job.budget.toStringAsFixed(0)})',
                  ),
                ),
              ],
              if (_paymentInfo != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Payment: ${_paymentInfo!.status}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (canRelease) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _releaseCodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Release code',
                    prefixIcon: Icon(Icons.key_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _working ? null : _verifyReleaseAndPay,
                  icon: const Icon(Icons.verified_rounded),
                  label: const Text('Verify Release & Release Payment'),
                ),
              ],
              if (canCancel) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _working ? null : _cancelJob,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Job'),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _working ? null : _deleteJob,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.danger,
                  side: const BorderSide(color: AppPalette.danger),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete Job'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _showJobDetailSheet(BuildContext context, JobItem job) {
  final dueDate = DateFormat('dd MMM yyyy').format(job.dueDate);

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
                  MetaPill(label: 'Job ID: ${job.id}'),
                  MetaPill(label: 'Category: ${job.category}'),
                  MetaPill(label: 'Location: ${job.location}'),
                  MetaPill(label: 'Budget: ₹${job.budget.toStringAsFixed(0)}'),
                  MetaPill(label: 'Due: $dueDate'),
                  MetaPill(label: 'Status: ${job.status.label}'),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

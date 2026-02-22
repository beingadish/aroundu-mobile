import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_api.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../chat/view/conversations_view.dart';
import '../../profile/view/profile_view.dart';
import '../../review/view/leave_review_view.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../core/widgets/payment_status_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../model/job_item.dart';
import '../model/job_workflow_models.dart';
import '../view_model/job_view_model.dart';
import '../view_model/navigation_view_model.dart';
import '../view_model/skill_suggest_view_model.dart';
import 'location_picker_screen.dart';
import 'widgets/job_card.dart';
import 'widgets/job_shared_widgets.dart';
import 'widgets/skill_suggest_field.dart';

class ProviderShellScreen extends ConsumerWidget {
  const ProviderShellScreen({super.key});

  static const List<String> _titles = [
    'My Tasks',
    'Post Task',
    'Messages',
    'Profile',
  ];

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
          ConversationsScreen(),
          ProfileScreen(),
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
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Post',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
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

  Future<void> _openWorkflowSheet(BuildContext context, JobItem job) async {
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

  String _urgency = 'NORMAL';
  String _paymentMode = 'OFFLINE';
  AddressInfo? _selectedAddress;
  bool _isRegisteringAddress = false;

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

  Future<void> _openLocationPicker() async {
    final picked = await Navigator.of(context).push<AddressInfo>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const LocationPickerScreen(),
      ),
    );
    if (picked == null || !mounted) return;

    // If the address already has a backend ID, use it directly.
    if (picked.id != null) {
      setState(() => _selectedAddress = picked);
      return;
    }

    // Otherwise we need to register the pinned location first.
    setState(() => _isRegisteringAddress = true);
    try {
      final auth = ref.read(authControllerProvider);
      final authApi = ref.read(authApiProvider);
      final registered = await authApi.addAddress(
        token: auth.token!,
        clientId: auth.userId!,
        address: picked,
      );
      await ref.read(authControllerProvider.notifier).refreshProfile();
      if (mounted) setState(() => _selectedAddress = registered);
    } on ApiException catch (e) {
      if (mounted) AppNotifier.showError(context, e.userMessage);
    } catch (_) {
      if (mounted) AppNotifier.showError(context, 'Failed to save location');
    } finally {
      if (mounted) setState(() => _isRegisteringAddress = false);
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final selectedSkillNames =
        ref.read(skillSuggestControllerProvider.notifier).selectedNames;
    if (selectedSkillNames.isEmpty) {
      AppNotifier.showWarning(
        context,
        'Add at least one required skill for this task',
      );
      return;
    }

    final budget = double.tryParse(_budgetController.text.trim());
    if (budget == null || budget <= 0) {
      AppNotifier.showWarning(context, 'Enter a valid budget amount');
      return;
    }

    final auth = ref.read(authControllerProvider);
    final locationId =
        _selectedAddress?.id ?? auth.currentAddressId;
    if (locationId == null) {
      AppNotifier.showWarning(
        context,
        'Please set a job location before posting',
      );
      return;
    }

    final input = NewJobInput(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: '',
      budget: budget,
      skillNames: selectedSkillNames,
      jobUrgency: _urgency,
      paymentMode: _paymentMode,
      overrideLocationId: locationId,
    );

    final success = await ref
        .read(createJobControllerProvider.notifier)
        .submit(input);

    if (!mounted) return;

    if (success) {
      _titleController.clear();
      _descriptionController.clear();
      _budgetController.clear();
      ref.read(skillSuggestControllerProvider.notifier).clearAll();
      setState(() {
        _urgency = 'NORMAL';
        _paymentMode = 'OFFLINE';
        _selectedAddress = null;
      });

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
    if (error is ApiException) return error.userMessage;
    final message = error?.toString().trim();
    if (message == null || message.isEmpty) {
      return 'Failed to post job. Please retry.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(createJobControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final isSubmitting = submitState.isLoading;

    final displayAddress = _selectedAddress ?? auth.currentAddressFull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Post a New Task',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Add clear details so workers can send accurate offers.',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title ──────────────────────────────────────────
                      TextFormField(
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        validator: (value) => _required(value, 'Title'),
                        decoration: const InputDecoration(
                          labelText: 'Task title',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Skills ─────────────────────────────────────────
                      SkillSuggestField(
                        controllerProvider: skillSuggestControllerProvider,
                      ),
                      const SizedBox(height: 12),

                      // ── Budget ─────────────────────────────────────────
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

                      // ── Description ────────────────────────────────────
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
                      const SizedBox(height: 16),

                      // ── Urgency ────────────────────────────────────────
                      Text(
                        'Urgency',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _UrgencyChip(
                            label: 'Normal',
                            value: 'NORMAL',
                            icon: Icons.schedule_rounded,
                            color: Colors.green,
                            selected: _urgency == 'NORMAL',
                            onTap: () => setState(() => _urgency = 'NORMAL'),
                          ),
                          _UrgencyChip(
                            label: 'Medium',
                            value: 'MEDIUM',
                            icon: Icons.hourglass_bottom_rounded,
                            color: Colors.amber,
                            selected: _urgency == 'MEDIUM',
                            onTap: () => setState(() => _urgency = 'MEDIUM'),
                          ),
                          _UrgencyChip(
                            label: 'Urgent',
                            value: 'URGENT',
                            icon: Icons.priority_high_rounded,
                            color: Colors.orange,
                            selected: _urgency == 'URGENT',
                            onTap: () => setState(() => _urgency = 'URGENT'),
                          ),
                          _UrgencyChip(
                            label: 'ASAP',
                            value: 'SUPER_URGENT',
                            icon: Icons.flash_on_rounded,
                            color: Colors.red,
                            selected: _urgency == 'SUPER_URGENT',
                            onTap: () =>
                                setState(() => _urgency = 'SUPER_URGENT'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Payment Mode ───────────────────────────────────
                      Text(
                        'Payment Method',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'OFFLINE',
                            label: Text('Pay in Cash'),
                            icon: Icon(Icons.payments_outlined),
                          ),
                          ButtonSegment(
                            value: 'ESCROW',
                            label: Text('Secure Escrow'),
                            icon: Icon(Icons.lock_outline_rounded),
                          ),
                        ],
                        selected: {_paymentMode},
                        onSelectionChanged: (selected) {
                          if (selected.isNotEmpty) {
                            setState(() => _paymentMode = selected.first);
                          }
                        },
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Location ───────────────────────────────────────
                      Text(
                        'Job Location',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      _isRegisteringAddress
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(strokeWidth: 2),
                                    SizedBox(width: 10),
                                    Text('Saving location…'),
                                  ],
                                ),
                              ),
                            )
                          : InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _openLocationPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: displayAddress != null
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  // Full address is the rich primary label
                                                  displayAddress.fullAddress ??
                                                      displayAddress.displayName,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                // Short area/city as subtitle when different
                                                if (displayAddress.displayName !=
                                                    (displayAddress.fullAddress ??
                                                        displayAddress
                                                            .displayName))
                                                  Text(
                                                    displayAddress.displayName,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            )
                                          : Text(
                                              'Tap to select location',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .outline,
                                                  ),
                                            ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      const SizedBox(height: 20),

                      // ── Submit ─────────────────────────────────────────
                      PrimaryButton(
                        label: 'Post Task',
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

/// A compact choice chip used for the urgency selector.
class _UrgencyChip extends StatelessWidget {
  const _UrgencyChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 16, color: selected ? Colors.white : color),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: selected ? FontWeight.w600 : null,
      ),
      showCheckmark: false,
    );
  }
}

// _ProviderAccountTab removed – replaced by ProfileScreen in IndexedStack

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
    }, successMessage: 'Offer accepted');
  }

  Future<void> _generateCodes() {
    return _runAction(() async {
      final result = await ref
          .read(jobRepositoryProvider)
          .generateCodes(widget.jobId);
      _codeInfo = result;
    }, successMessage: 'Task codes generated');
  }

  Future<void> _lockEscrow() {
    final job = _job;
    if (job == null) {
      return Future<void>.value();
    }

    return _runAction(() async {
      _paymentInfo = await ref
          .read(jobRepositoryProvider)
          .lockEscrow(jobId: widget.jobId, amount: job.budget);
    }, successMessage: 'Payment safely reserved');
  }

  Future<void> _verifyReleaseAndPay() {
    final code = _releaseCodeController.text.trim();
    if (code.isEmpty) {
      AppNotifier.showWarning(context, 'Enter release code first');
      return Future<void>.value();
    }

    return _runAction(() async {
      _codeInfo = await ref
          .read(jobRepositoryProvider)
          .verifyReleaseCode(jobId: widget.jobId, code: code);
      _paymentInfo = await ref
          .read(jobRepositoryProvider)
          .releaseEscrow(jobId: widget.jobId, releaseCode: code);
    }, successMessage: 'Release verified — payment released');
  }

  Future<void> _cancelJob() {
    return _runAction(
      () async {
        _job = await ref
            .read(jobRepositoryProvider)
            .updateJobStatus(jobId: widget.jobId, newStatus: 'CANCELLED');
      },
      successMessage: 'Task cancelled',
      reload: true,
    );
  }

  Future<void> _deleteJob() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete task?'),
          content: const Text(
            'This will remove the task and all associated offers.',
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

    await _runAction(
      () async {
        await ref.read(jobRepositoryProvider).deleteJob(widget.jobId);
      },
      successMessage: 'Task deleted',
      reload: false,
    );

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
            Text('Offers', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        if (_bids.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'No offers received yet.',
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
                      'Offer: ${bid.bidAmount.toStringAsFixed(0)}',
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
                          label: const Text('Accept Offer'),
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
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _codeInfo!.startCode!),
                        );
                        AppNotifier.showInfo(context, 'Start code copied');
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
                    'Reserve Payment (${job.budget.toStringAsFixed(0)})',
                  ),
                ),
              ],
              if (_paymentInfo != null) ...[
                const SizedBox(height: 8),
                PaymentStatusBanner(
                  status: _paymentInfo!.status,
                  amount: job.budget,
                  currency: 'INR',
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
                  label: const Text('Verify & Release Payment'),
                ),
              ],
              if (canCancel) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _working ? null : _cancelJob,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Task'),
                ),
              ],
              if (statusCode == 'COMPLETED') ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<bool>(
                        builder: (_) => LeaveReviewScreen(
                          jobId: widget.jobId,
                          workerName:
                              _bids
                                  .where(
                                    (b) => b.status.toUpperCase() == 'SELECTED',
                                  )
                                  .map((b) => 'Worker #${b.workerId}')
                                  .firstOrNull ??
                              'Worker',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Leave a Review'),
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
                label: const Text('Delete Task'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

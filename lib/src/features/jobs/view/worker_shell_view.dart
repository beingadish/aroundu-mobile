import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/view_model/auth_view_model.dart';
import '../../chat/view/conversations_view.dart';
import '../../profile/view/profile_view.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../core/widgets/primary_button.dart';
import '../model/job_item.dart';
import '../model/job_workflow_models.dart';
import '../view_model/job_view_model.dart';
import '../view_model/navigation_view_model.dart';
import '../view_model/skill_suggest_view_model.dart';
import '../view_model/worker_skills_view_model.dart';
import 'widgets/job_card.dart';
import 'widgets/job_shared_widgets.dart';
import 'widgets/skill_suggest_field.dart';

class WorkerShellScreen extends ConsumerWidget {
  const WorkerShellScreen({super.key});

  static const List<String> _titles = [
    'Task Feed',
    'Skills',
    'Messages',
    'Profile',
  ];

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
          ConversationsScreen(),
          ProfileScreen(),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSkills = ref.watch(workerSkillsProvider);
    final suggestState = ref.watch(skillSuggestControllerProvider);

    // When a skill is picked in the overlay, also add it to workerSkillsProvider
    // We do this by watching suggested selections via a listener pattern on the
    // overlay selection (the SkillSuggestField calls notifier.selectSkill).
    // Use an inline sync via a post-frame callback to bridge the two providers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final skill in suggestState.selected) {
        ref
            .read(workerSkillsProvider.notifier)
            .toggleSkill(skill.skillName, true);
      }
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Your Skills', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Search and add skills. These are sent to the server to filter your job feed.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        // ── Skill search ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SkillSuggestField(
              controllerProvider: skillSuggestControllerProvider,
              label: 'Add Skill',
              hintText: 'Type to search skills…',
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── Currently saved skills from workerSkillsProvider ──
        if (selectedSkills.isNotEmpty) ...[
          Text(
            'Saved Skills (${selectedSkills.length})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedSkills.map((skill) {
              return Chip(
                label: Text(skill),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => ref
                    .read(workerSkillsProvider.notifier)
                    .toggleSkill(skill, false),
              );
            }).toList(),
          ),
        ] else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'No skills added yet. Search above to add relevant skills.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
      ],
    );
  }
}

// _WorkerAccountTab removed – replaced by ProfileScreen in IndexedStack

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

class _WorkerJobWorkflowSheetState
    extends ConsumerState<_WorkerJobWorkflowSheet> {
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
      AppNotifier.showWarning(context, 'Enter a valid offer amount');
      return Future<void>.value();
    }

    return _runAction(() async {
      await ref
          .read(jobRepositoryProvider)
          .placeBid(
            PlaceBidInput(
              jobId: widget.jobId,
              amount: amount,
              partnerName: _partnerNameController.text,
              partnerFee: double.tryParse(_partnerFeeController.text.trim()),
              notes: _notesController.text,
            ),
          );
    }, successMessage: 'Offer submitted successfully');
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
    }, successMessage: 'Start code verified. Task is now in progress.');
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
            'Unable to load task details',
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
              MetaPill(
                label: 'Distance: ${job.distanceKm!.toStringAsFixed(1)} km',
              ),
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
                  Text(
                    'Your Offer',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
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
                  if (myBid.notes != null &&
                      myBid.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      myBid.notes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (canPlaceBid) ...[
          Text('Place Offer', style: Theme.of(context).textTheme.titleMedium),
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
                      labelText: 'Offer amount',
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
                    label: 'Submit Offer',
                    onPressed: _working ? null : _placeBid,
                  ),
                ],
              ),
            ),
          ),
        ],
        if (canHandshake) ...[
          Text(
            'Client selected your offer',
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
          Text(
            'Verify Start Code',
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
                'Work is in progress. Wait for the client to verify and release payment.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

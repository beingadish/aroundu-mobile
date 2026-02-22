import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/job_api.dart';
import '../model/job_item.dart';
import '../model/job_workflow_models.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';

class NewJobInput {
  const NewJobInput({
    required this.title,
    required this.description,
    required this.category,
    required this.budget,
    this.skillNames = const <String>[],
    this.jobUrgency = 'NORMAL',
    this.paymentMode = 'OFFLINE',
    this.overrideLocationId,
  });

  final String title;
  final String description;
  final String category;
  final double budget;
  final List<String> skillNames;
  /// Backend JobUrgency enum: NORMAL | MEDIUM | URGENT | SUPER_URGENT
  final String jobUrgency;
  /// Backend PaymentMode enum: OFFLINE | ESCROW
  final String paymentMode;
  /// When non-null, overrides the profile's currentAddressId as jobLocationId.
  final int? overrideLocationId;
}

class PlaceBidInput {
  const PlaceBidInput({
    required this.jobId,
    required this.amount,
    this.partnerName,
    this.partnerFee,
    this.notes,
  });

  final int jobId;
  final double amount;
  final String? partnerName;
  final double? partnerFee;
  final String? notes;
}

abstract class JobRepository {
  Future<List<JobItem>> fetchProviderJobs();
  Future<List<JobItem>> fetchProviderPastJobs();
  Future<List<JobItem>> fetchWorkerFeed();
  Future<void> createJob(NewJobInput input);

  Future<JobItem> fetchJobForCurrentRole(int jobId);
  Future<JobItem> updateJobStatus({required int jobId, required String newStatus});
  Future<void> deleteJob(int jobId);

  Future<List<BidItem>> fetchBids(int jobId);
  Future<BidItem> placeBid(PlaceBidInput input);
  Future<BidItem> acceptBid(int bidId);
  Future<BidItem> handshakeBid({required int bidId, required bool accepted});

  Future<JobCodeInfo> generateCodes(int jobId);
  Future<JobCodeInfo> verifyStartCode({required int jobId, required String code});
  Future<JobCodeInfo> verifyReleaseCode({
    required int jobId,
    required String code,
  });

  Future<PaymentInfo> lockEscrow({required int jobId, required double amount});
  Future<PaymentInfo> releaseEscrow({
    required int jobId,
    required String releaseCode,
  });
}

class ApiJobRepository implements JobRepository {
  const ApiJobRepository({required JobApi jobApi, required AuthState authState})
    : _jobApi = jobApi,
      _authState = authState;

  final JobApi _jobApi;
  final AuthState _authState;

  @override
  Future<List<JobItem>> fetchProviderJobs() async {
    if (!_authState.isAuthenticated || _authState.userId == null) {
      return const <JobItem>[];
    }

    if (_authState.role != UserRole.provider) {
      return const <JobItem>[];
    }

    final jobs = await _jobApi.fetchClientJobs(
      token: _authState.token!,
      clientId: _authState.userId!,
      page: 0,
      size: 30,
      sortBy: 'createdAt',
      sortDirection: 'DESC',
    );

    return jobs.map(_mapSummaryToJobItem).toList();
  }

  @override
  Future<List<JobItem>> fetchProviderPastJobs() async {
    if (!_authState.isAuthenticated || _authState.userId == null) {
      return const <JobItem>[];
    }

    if (_authState.role != UserRole.provider) {
      return const <JobItem>[];
    }

    final jobs = await _jobApi.fetchClientPastJobs(
      token: _authState.token!,
      clientId: _authState.userId!,
      page: 0,
      size: 30,
    );

    return jobs.map(_mapSummaryToJobItem).toList();
  }

  @override
  Future<List<JobItem>> fetchWorkerFeed() async {
    if (!_authState.isAuthenticated || _authState.userId == null) {
      return const <JobItem>[];
    }

    if (_authState.role != UserRole.worker) {
      return const <JobItem>[];
    }

    final jobs = await _jobApi.fetchWorkerFeed(
      token: _authState.token!,
      workerId: _authState.userId!,
      skillIds: _authState.skillIds,
      page: 0,
      size: 30,
      sortByDistance: true,
    );

    return jobs.map(_mapSummaryToJobItem).toList();
  }

  @override
  Future<void> createJob(NewJobInput input) async {
    _requireAuthenticatedRole(UserRole.provider);

    final locationId = _authState.currentAddressId;
    if (locationId == null) {
      throw const ApiException(
        'Provider profile location is missing. Please update profile.',
      );
    }

    await _jobApi.createJob(
      token: _authState.token!,
      clientId: _authState.userId!,
      jobLocationId: input.overrideLocationId ?? locationId,
      title: input.title.trim(),
      description: input.description.trim(),
      currency: _authState.currency,
      amount: input.budget,
      skillNames: input.skillNames.isNotEmpty ? input.skillNames : const <String>[],
      skillIds: input.skillNames.isEmpty
          ? _skillIdsForCategory(input.category)
          : const <int>[],
      jobUrgency: input.jobUrgency,
      paymentMode: input.paymentMode,
    );
  }

  @override
  Future<JobItem> fetchJobForCurrentRole(int jobId) async {
    _requireAuthenticated();

    if (_authState.role == UserRole.provider) {
      final detail = await _jobApi.fetchJobForClient(
        token: _authState.token!,
        clientId: _authState.userId!,
        jobId: jobId,
      );
      return _mapDetailToJobItem(detail);
    }

    if (_authState.role == UserRole.worker) {
      final detail = await _jobApi.fetchJobForWorker(
        token: _authState.token!,
        workerId: _authState.userId!,
        jobId: jobId,
      );
      return _mapDetailToJobItem(detail);
    }

    final detail = await _jobApi.fetchPublicJob(jobId);
    return _mapDetailToJobItem(detail);
  }

  @override
  Future<JobItem> updateJobStatus({
    required int jobId,
    required String newStatus,
  }) async {
    _requireAuthenticatedRole(UserRole.provider);

    final updated = await _jobApi.updateJobStatus(
      token: _authState.token!,
      clientId: _authState.userId!,
      jobId: jobId,
      newStatus: newStatus,
    );

    return _mapDetailToJobItem(updated);
  }

  @override
  Future<void> deleteJob(int jobId) async {
    _requireAuthenticatedRole(UserRole.provider);

    await _jobApi.deleteJob(
      token: _authState.token!,
      clientId: _authState.userId!,
      jobId: jobId,
    );
  }

  @override
  Future<List<BidItem>> fetchBids(int jobId) async {
    _requireAuthenticated();

    final bids = await _jobApi.listBidsForJob(token: _authState.token!, jobId: jobId);
    return bids.map(BidItem.fromMap).toList();
  }

  @override
  Future<BidItem> placeBid(PlaceBidInput input) async {
    _requireAuthenticatedRole(UserRole.worker);

    final bid = await _jobApi.placeBid(
      token: _authState.token!,
      jobId: input.jobId,
      workerId: _authState.userId!,
      bidAmount: input.amount,
      partnerName: input.partnerName,
      partnerFee: input.partnerFee,
      notes: input.notes,
    );

    return BidItem.fromMap(bid);
  }

  @override
  Future<BidItem> acceptBid(int bidId) async {
    _requireAuthenticatedRole(UserRole.provider);

    final bid = await _jobApi.acceptBid(
      token: _authState.token!,
      bidId: bidId,
      clientId: _authState.userId!,
    );

    return BidItem.fromMap(bid);
  }

  @override
  Future<BidItem> handshakeBid({
    required int bidId,
    required bool accepted,
  }) async {
    _requireAuthenticatedRole(UserRole.worker);

    final bid = await _jobApi.handshakeBid(
      token: _authState.token!,
      bidId: bidId,
      workerId: _authState.userId!,
      accepted: accepted,
    );

    return BidItem.fromMap(bid);
  }

  @override
  Future<JobCodeInfo> generateCodes(int jobId) async {
    _requireAuthenticatedRole(UserRole.provider);

    final info = await _jobApi.generateJobCodes(
      token: _authState.token!,
      jobId: jobId,
      clientId: _authState.userId!,
    );

    return JobCodeInfo.fromMap(info);
  }

  @override
  Future<JobCodeInfo> verifyStartCode({
    required int jobId,
    required String code,
  }) async {
    _requireAuthenticatedRole(UserRole.worker);

    final info = await _jobApi.verifyStartCode(
      token: _authState.token!,
      jobId: jobId,
      workerId: _authState.userId!,
      code: code,
    );

    return JobCodeInfo.fromMap(info);
  }

  @override
  Future<JobCodeInfo> verifyReleaseCode({
    required int jobId,
    required String code,
  }) async {
    _requireAuthenticatedRole(UserRole.provider);

    final info = await _jobApi.verifyReleaseCode(
      token: _authState.token!,
      jobId: jobId,
      clientId: _authState.userId!,
      code: code,
    );

    return JobCodeInfo.fromMap(info);
  }

  @override
  Future<PaymentInfo> lockEscrow({
    required int jobId,
    required double amount,
  }) async {
    _requireAuthenticatedRole(UserRole.provider);

    final info = await _jobApi.lockEscrowPayment(
      token: _authState.token!,
      jobId: jobId,
      clientId: _authState.userId!,
      amount: amount,
    );

    return PaymentInfo.fromMap(info);
  }

  @override
  Future<PaymentInfo> releaseEscrow({
    required int jobId,
    required String releaseCode,
  }) async {
    _requireAuthenticatedRole(UserRole.provider);

    final info = await _jobApi.releaseEscrowPayment(
      token: _authState.token!,
      jobId: jobId,
      clientId: _authState.userId!,
      releaseCode: releaseCode,
    );

    return PaymentInfo.fromMap(info);
  }

  JobItem _mapSummaryToJobItem(Map<String, dynamic> raw) {
    final createdAt =
        DateTime.tryParse(raw['createdAt']?.toString() ?? '') ?? DateTime.now();

    final price = _asMap(raw['price']);
    final amount = _toDouble(price['amount']) ?? 0;
    final statusText = raw['jobStatus']?.toString() ?? '';

    return JobItem(
      jobId: _asInt(raw['id']) ?? 0,
      id: 'JOB-${raw['id']?.toString() ?? '0'}',
      title: raw['title']?.toString() ?? 'Untitled Job',
      description:
          raw['shortDescription']?.toString() ?? 'Description unavailable',
      category: _mapUrgencyToCategory(raw['jobUrgency']?.toString()),
      location: 'Location available on job detail',
      budget: amount,
      createdAt: createdAt,
      dueDate: createdAt.add(const Duration(days: 2)),
      status: _mapStatus(statusText),
      statusCode: statusText,
      paymentMode: raw['paymentMode']?.toString(),
      distanceKm: _toDouble(raw['distanceKm']),
    );
  }

  JobItem _mapDetailToJobItem(Map<String, dynamic> raw) {
    final createdAt =
        DateTime.tryParse(raw['createdAt']?.toString() ?? '') ?? DateTime.now();
    final updatedAt =
        DateTime.tryParse(raw['updatedAt']?.toString() ?? '') ?? createdAt;

    final price = _asMap(raw['price']);
    final amount = _toDouble(price['amount']) ?? 0;

    final locationMap = _asMap(raw['jobLocation']);
    final location =
        locationMap['fullAddress']?.toString() ??
        [locationMap['area'], locationMap['city']]
            .where((value) => value != null && value.toString().trim().isNotEmpty)
            .map((value) => value.toString())
            .join(', ')
            .trim();

    final statusText = raw['jobStatus']?.toString() ?? '';

    final requiredSkills = <String>[];
    final skillList = raw['requiredSkills'];
    if (skillList is List) {
      for (final skill in skillList) {
        if (skill is Map<String, dynamic>) {
          final name = skill['skillName']?.toString();
          if (name != null && name.trim().isNotEmpty) {
            requiredSkills.add(name.trim());
          }
        }
      }
    }

    return JobItem(
      jobId: _asInt(raw['id']) ?? 0,
      id: 'JOB-${raw['id']?.toString() ?? '0'}',
      title: raw['title']?.toString() ?? 'Untitled Job',
      description:
          raw['longDescription']?.toString() ??
          raw['shortDescription']?.toString() ??
          'Description unavailable',
      category: _mapUrgencyToCategory(raw['jobUrgency']?.toString()),
      location: location.isEmpty ? 'Location unavailable' : location,
      budget: amount,
      createdAt: createdAt,
      dueDate: updatedAt.add(const Duration(days: 2)),
      status: _mapStatus(statusText),
      statusCode: statusText,
      paymentMode: raw['paymentMode']?.toString(),
      requiredSkillNames: requiredSkills,
    );
  }

  void _requireAuthenticated() {
    if (!_authState.isAuthenticated || _authState.userId == null) {
      throw const ApiException('Please log in first');
    }
  }

  void _requireAuthenticatedRole(UserRole role) {
    _requireAuthenticated();
    if (_authState.role != role) {
      final roleLabel = switch (role) {
        UserRole.provider => 'providers',
        UserRole.worker => 'workers',
        UserRole.admin => 'admins',
      };
      throw ApiException('Only $roleLabel can perform this action');
    }
  }

  JobStatus _mapStatus(String value) {
    switch (value.toUpperCase()) {
      case 'BID_SELECTED_AWAITING_HANDSHAKE':
        return JobStatus.bidAccepted;
      case 'READY_TO_START':
        return JobStatus.readyToStart;
      case 'IN_PROGRESS':
        return JobStatus.inProgress;
      case 'COMPLETED_PENDING_PAYMENT':
        return JobStatus.completedPendingPayment;
      case 'PAYMENT_RELEASED':
        return JobStatus.paymentReleased;
      case 'COMPLETED':
        return JobStatus.completed;
      case 'CANCELLED':
      case 'JOB_CLOSED_DUE_TO_EXPIRATION':
        return JobStatus.cancelled;
      case 'OPEN_FOR_BIDS':
      case 'CREATED':
      default:
        return JobStatus.openForBids;
    }
  }

  String _mapUrgencyToCategory(String? urgency) {
    switch ((urgency ?? '').toUpperCase()) {
      case 'SUPER_URGENT':
      case 'URGENT':
        return 'Urgent';
      case 'MEDIUM':
        return 'Standard';
      case 'NORMAL':
      default:
        return 'General';
    }
  }

  List<int> _skillIdsForCategory(String category) {
    switch (category.trim().toLowerCase()) {
      case 'plumbing':
        return const <int>[1];
      case 'electrical':
        return const <int>[3];
      case 'carpentry':
        return const <int>[4];
      case 'painting':
        return const <int>[5];
      case 'cleaning':
        return const <int>[6];
      default:
        return const <int>[1];
    }
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return const <String, dynamic>{};
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  double? _toDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }
}

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return ApiJobRepository(
    jobApi: ref.watch(jobApiProvider),
    authState: ref.watch(authControllerProvider),
  );
});

class ProviderJobsController extends AsyncNotifier<List<JobItem>> {
  @override
  Future<List<JobItem>> build() {
    return ref.read(jobRepositoryProvider).fetchProviderJobs();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(jobRepositoryProvider).fetchProviderJobs(),
    );
  }
}

final providerJobsControllerProvider =
    AsyncNotifierProvider<ProviderJobsController, List<JobItem>>(
      ProviderJobsController.new,
    );

class ProviderPastJobsController extends AsyncNotifier<List<JobItem>> {
  @override
  Future<List<JobItem>> build() {
    return ref.read(jobRepositoryProvider).fetchProviderPastJobs();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(jobRepositoryProvider).fetchProviderPastJobs(),
    );
  }
}

final providerPastJobsControllerProvider =
    AsyncNotifierProvider<ProviderPastJobsController, List<JobItem>>(
      ProviderPastJobsController.new,
    );

class WorkerFeedController extends AsyncNotifier<List<JobItem>> {
  @override
  Future<List<JobItem>> build() {
    return ref.read(jobRepositoryProvider).fetchWorkerFeed();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(jobRepositoryProvider).fetchWorkerFeed(),
    );
  }
}

final workerFeedControllerProvider =
    AsyncNotifierProvider<WorkerFeedController, List<JobItem>>(
      WorkerFeedController.new,
    );

class CreateJobController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> submit(NewJobInput input) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => ref.read(jobRepositoryProvider).createJob(input),
    );
    state = result;

    if (result.hasError) {
      return false;
    }

    ref.invalidate(providerJobsControllerProvider);
    ref.invalidate(providerPastJobsControllerProvider);
    ref.invalidate(workerFeedControllerProvider);
    return true;
  }
}

final createJobControllerProvider =
    AsyncNotifierProvider<CreateJobController, void>(CreateJobController.new);

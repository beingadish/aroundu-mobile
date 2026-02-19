import 'package:aroundu/src/core/network/api_exception.dart';
import 'package:aroundu/src/features/jobs/model/job_item.dart';
import 'package:aroundu/src/features/jobs/model/job_workflow_models.dart';
import 'package:aroundu/src/features/jobs/view_model/job_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeJobRepository implements JobRepository {
  List<JobItem> providerJobs;
  List<JobItem> workerJobs;
  Object? createFailure;
  int createCalls = 0;
  NewJobInput? lastInput;

  FakeJobRepository({
    this.providerJobs = const <JobItem>[],
    this.workerJobs = const <JobItem>[],
    this.createFailure,
  });

  @override
  Future<void> createJob(NewJobInput input) async {
    createCalls += 1;
    lastInput = input;
    if (createFailure != null) {
      throw createFailure!;
    }
  }

  @override
  Future<BidItem> acceptBid(int bidId) async {
    return BidItem(
      id: bidId,
      jobId: 1,
      workerId: 2,
      bidAmount: 1200,
      status: 'SELECTED',
    );
  }

  @override
  Future<void> deleteJob(int jobId) async {}

  @override
  Future<List<JobItem>> fetchProviderJobs() async {
    return providerJobs;
  }

  @override
  Future<List<JobItem>> fetchProviderPastJobs() async {
    return const <JobItem>[];
  }

  @override
  Future<List<BidItem>> fetchBids(int jobId) async {
    return const <BidItem>[];
  }

  @override
  Future<JobItem> fetchJobForCurrentRole(int jobId) async {
    return _job('$jobId');
  }

  @override
  Future<List<JobItem>> fetchWorkerFeed() async {
    return workerJobs;
  }

  @override
  Future<JobCodeInfo> generateCodes(int jobId) async {
    return JobCodeInfo(id: 1, jobId: jobId, status: 'START_PENDING');
  }

  @override
  Future<BidItem> handshakeBid({required int bidId, required bool accepted}) async {
    return BidItem(
      id: bidId,
      jobId: 1,
      workerId: 2,
      bidAmount: 1200,
      status: accepted ? 'SELECTED' : 'REJECTED',
    );
  }

  @override
  Future<PaymentInfo> lockEscrow({required int jobId, required double amount}) async {
    return PaymentInfo(
      id: 1,
      jobId: jobId,
      clientId: 1,
      workerId: 2,
      amount: amount,
      paymentMode: 'ESCROW',
      status: 'ESCROW_LOCKED',
    );
  }

  @override
  Future<BidItem> placeBid(PlaceBidInput input) async {
    return BidItem(
      id: 1,
      jobId: input.jobId,
      workerId: 2,
      bidAmount: input.amount,
      status: 'PENDING',
    );
  }

  @override
  Future<PaymentInfo> releaseEscrow({
    required int jobId,
    required String releaseCode,
  }) async {
    return PaymentInfo(
      id: 1,
      jobId: jobId,
      clientId: 1,
      workerId: 2,
      amount: 1200,
      paymentMode: 'ESCROW',
      status: 'RELEASED',
    );
  }

  @override
  Future<JobItem> updateJobStatus({required int jobId, required String newStatus}) async {
    return _job('$jobId');
  }

  @override
  Future<JobCodeInfo> verifyReleaseCode({
    required int jobId,
    required String code,
  }) async {
    return JobCodeInfo(id: 1, jobId: jobId, status: 'COMPLETED');
  }

  @override
  Future<JobCodeInfo> verifyStartCode({
    required int jobId,
    required String code,
  }) async {
    return JobCodeInfo(id: 1, jobId: jobId, status: 'RELEASE_PENDING');
  }
}

JobItem _job(String id) {
  return JobItem(
    id: id,
    title: 'Job $id',
    description: 'Test job',
    category: 'General',
    location: 'Location',
    budget: 1000,
    createdAt: DateTime(2026, 2, 1),
    dueDate: DateTime(2026, 2, 3),
    status: JobStatus.openForBids,
  );
}

const NewJobInput _newJobInput = NewJobInput(
  title: 'Fix tap',
  description: 'Kitchen tap replacement',
  category: 'Plumbing',
  budget: 1800,
);

void main() {
  group('Jobs ViewModels', () {
    test('ProviderJobsController returns repository jobs', () async {
      final repo = FakeJobRepository(providerJobs: <JobItem>[_job('1')]);
      final container = ProviderContainer(
        overrides: [jobRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final jobs = await container.read(providerJobsControllerProvider.future);
      expect(jobs, hasLength(1));
      expect(jobs.first.id, '1');
    });

    test(
      'WorkerFeedController refreshes with latest repository data',
      () async {
        final repo = FakeJobRepository(workerJobs: <JobItem>[_job('2')]);
        final container = ProviderContainer(
          overrides: [jobRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        final initial = await container.read(
          workerFeedControllerProvider.future,
        );
        expect(initial, hasLength(1));
        expect(initial.first.id, '2');

        repo.workerJobs = <JobItem>[_job('3'), _job('4')];
        await container.read(workerFeedControllerProvider.notifier).refresh();
        final refreshed = container
            .read(workerFeedControllerProvider)
            .valueOrNull;

        expect(refreshed, isNotNull);
        expect(refreshed, hasLength(2));
        expect(refreshed!.first.id, '3');
      },
    );

    test('CreateJobController submit succeeds and forwards input', () async {
      final repo = FakeJobRepository();
      final container = ProviderContainer(
        overrides: [jobRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final success = await container
          .read(createJobControllerProvider.notifier)
          .submit(_newJobInput);

      expect(success, isTrue);
      expect(repo.createCalls, 1);
      expect(repo.lastInput?.title, 'Fix tap');
      expect(container.read(createJobControllerProvider).hasError, isFalse);
    });

    test('CreateJobController submit exposes async error state', () async {
      final repo = FakeJobRepository(
        createFailure: const ApiException('Unable to create job'),
      );
      final container = ProviderContainer(
        overrides: [jobRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final success = await container
          .read(createJobControllerProvider.notifier)
          .submit(_newJobInput);

      expect(success, isFalse);
      expect(repo.createCalls, 1);
      expect(container.read(createJobControllerProvider).hasError, isTrue);
    });
  });
}

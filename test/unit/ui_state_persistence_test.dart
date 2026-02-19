import 'package:aroundu/src/core/providers/core_providers.dart';
import 'package:aroundu/src/core/storage/local_storage.dart';
import 'package:aroundu/src/features/jobs/view_model/navigation_view_model.dart';
import 'package:aroundu/src/features/jobs/view_model/worker_skills_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLocalStorage extends LocalStorage {
  int? providerTabIndex;
  int? workerTabIndex;
  Set<String> workerSkills = <String>{};

  @override
  Future<int?> readProviderTabIndex() async => providerTabIndex;

  @override
  Future<void> saveProviderTabIndex(int index) async {
    providerTabIndex = index;
  }

  @override
  Future<int?> readWorkerTabIndex() async => workerTabIndex;

  @override
  Future<void> saveWorkerTabIndex(int index) async {
    workerTabIndex = index;
  }

  @override
  Future<Set<String>> readWorkerSkills() async => <String>{...workerSkills};

  @override
  Future<void> saveWorkerSkills(Set<String> skills) async {
    workerSkills = <String>{...skills};
  }
}

void main() {
  group('UI state persistence', () {
    test('provider tab index persists and restores', () async {
      final storage = FakeLocalStorage();
      final container = ProviderContainer(
        overrides: [localStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      await container.read(providerTabIndexProvider.notifier).setIndex(2);
      expect(container.read(providerTabIndexProvider), 2);
      expect(storage.providerTabIndex, 2);

      final restoredContainer = ProviderContainer(
        overrides: [localStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(restoredContainer.dispose);

      restoredContainer.read(providerTabIndexProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(restoredContainer.read(providerTabIndexProvider), 2);
    });

    test('worker skills persist and restore', () async {
      final storage = FakeLocalStorage();
      final container = ProviderContainer(
        overrides: [localStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      await container
          .read(workerSkillsProvider.notifier)
          .toggleSkill('Mechanic', true);
      expect(container.read(workerSkillsProvider).contains('Mechanic'), isTrue);
      expect(storage.workerSkills.contains('Mechanic'), isTrue);

      final restoredContainer = ProviderContainer(
        overrides: [localStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(restoredContainer.dispose);

      restoredContainer.read(workerSkillsProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(
        restoredContainer.read(workerSkillsProvider).contains('Mechanic'),
        isTrue,
      );
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/providers/core_providers.dart';

/// Holds and persists worker-selected skill tags used by the skills tab UI.
class WorkerSkillsController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    _restore();
    return <String>{'Electrical', 'Plumbing'};
  }

  Future<void> toggleSkill(String skill, bool selected) async {
    final next = <String>{...state};
    if (selected) {
      next.add(skill);
    } else {
      next.remove(skill);
    }
    state = next;
    await _persist(next);
  }

  Future<void> _restore() async {
    try {
      final persisted = await ref.read(localStorageProvider).readWorkerSkills();
      if (persisted.isNotEmpty) {
        state = persisted;
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed restoring worker skills',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _persist(Set<String> skills) async {
    try {
      await ref.read(localStorageProvider).saveWorkerSkills(skills);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed persisting worker skills',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final workerSkillsProvider =
    NotifierProvider<WorkerSkillsController, Set<String>>(
      WorkerSkillsController.new,
    );

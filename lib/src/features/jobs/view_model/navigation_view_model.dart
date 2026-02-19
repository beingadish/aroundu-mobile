import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/providers/core_providers.dart';

class ProviderTabIndexController extends Notifier<int> {
  @override
  int build() {
    _restore();
    return 0;
  }

  Future<void> setIndex(int index) async {
    state = index;
    await ref.read(localStorageProvider).saveProviderTabIndex(index);
  }

  Future<void> reset() => setIndex(0);

  Future<void> _restore() async {
    try {
      final persisted = await ref
          .read(localStorageProvider)
          .readProviderTabIndex();
      if (persisted != null) {
        state = persisted;
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed restoring provider tab index',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

class WorkerTabIndexController extends Notifier<int> {
  @override
  int build() {
    _restore();
    return 0;
  }

  Future<void> setIndex(int index) async {
    state = index;
    await ref.read(localStorageProvider).saveWorkerTabIndex(index);
  }

  Future<void> reset() => setIndex(0);

  Future<void> _restore() async {
    try {
      final persisted = await ref
          .read(localStorageProvider)
          .readWorkerTabIndex();
      if (persisted != null) {
        state = persisted;
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed restoring worker tab index',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

class AdminTabIndexController extends Notifier<int> {
  @override
  int build() {
    _restore();
    return 0;
  }

  Future<void> setIndex(int index) async {
    state = index;
    await ref.read(localStorageProvider).saveAdminTabIndex(index);
  }

  Future<void> reset() => setIndex(0);

  Future<void> _restore() async {
    try {
      final persisted = await ref.read(localStorageProvider).readAdminTabIndex();
      if (persisted != null) {
        state = persisted;
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed restoring admin tab index',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final providerTabIndexProvider =
    NotifierProvider<ProviderTabIndexController, int>(
      ProviderTabIndexController.new,
    );

final workerTabIndexProvider = NotifierProvider<WorkerTabIndexController, int>(
  WorkerTabIndexController.new,
);

final adminTabIndexProvider = NotifierProvider<AdminTabIndexController, int>(
  AdminTabIndexController.new,
);

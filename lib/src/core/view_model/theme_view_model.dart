import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import '../providers/core_providers.dart';

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _persist(mode);
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }

  Future<void> _restore() async {
    try {
      final persisted = await ref.read(localStorageProvider).readThemeMode();
      final restored = _decodeThemeMode(persisted);
      if (restored != null) {
        state = restored;
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed restoring theme mode',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _persist(ThemeMode mode) async {
    try {
      await ref.read(localStorageProvider).saveThemeMode(mode.name);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed persisting theme mode',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  ThemeMode? _decodeThemeMode(String? raw) {
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

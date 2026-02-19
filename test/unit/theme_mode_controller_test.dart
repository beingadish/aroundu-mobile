import 'package:aroundu/src/core/providers/core_providers.dart';
import 'package:aroundu/src/core/storage/local_storage.dart';
import 'package:aroundu/src/core/view_model/theme_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLocalStorage extends LocalStorage {
  String? themeModeName;

  @override
  Future<String?> readThemeMode() async => themeModeName;

  @override
  Future<void> saveThemeMode(String themeModeName) async {
    this.themeModeName = themeModeName;
  }
}

void main() {
  group('ThemeModeController', () {
    test('toggles and persists theme mode', () async {
      final storage = FakeLocalStorage();
      final container = ProviderContainer(
        overrides: [localStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.light);
      await container.read(themeModeProvider.notifier).toggle();
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(storage.themeModeName, 'dark');
    });

    test('restores persisted dark mode on startup', () async {
      final storage = FakeLocalStorage()..themeModeName = 'dark';
      final container = ProviderContainer(
        overrides: [localStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      container.read(themeModeProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });
}

import 'package:flutter/foundation.dart';

class AppEnvironment {
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// API base URL resolution:
  /// 1) explicit `API_BASE_URL` dart-define
  /// 2) platform-aware local default (Android emulator -> 10.0.2.2)
  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:8080',
      _ => 'http://localhost:8080',
    };
  }
}

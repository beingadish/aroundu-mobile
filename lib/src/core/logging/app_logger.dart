import 'package:flutter/foundation.dart';

/// Lightweight logger used for API and ViewModel debugging.
class AppLogger {
  AppLogger._();

  static final bool _enabled =
      kDebugMode ||
      const bool.fromEnvironment('ENABLE_APP_LOGS', defaultValue: false);

  static void debug(String message) {
    if (!_enabled) {
      return;
    }
    debugPrint('[AroundU] $message');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_enabled) {
      return;
    }

    debugPrint('[AroundU][ERROR] $message');
    if (error != null) {
      debugPrint('[AroundU][ERROR] $error');
    }
    if (stackTrace != null) {
      debugPrint('[AroundU][ERROR] $stackTrace');
    }
  }
}

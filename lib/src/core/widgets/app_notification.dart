import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppNotificationType { success, error, info, warning }

/// Shows top overlay notifications with a custom AroundU style.
class AppNotifier {
  AppNotifier._();

  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: AppNotificationType.info,
      duration: duration,
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: AppNotificationType.success,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: AppNotificationType.warning,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: AppNotificationType.error,
      duration: duration,
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    required AppNotificationType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }

    _dismissTimer?.cancel();
    if (_activeEntry?.mounted ?? false) {
      _activeEntry!.remove();
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        final topPadding = MediaQuery.of(overlayContext).padding.top;
        return Positioned(
          left: 16,
          right: 16,
          top: topPadding + 12,
          child: SafeArea(
            bottom: false,
            child: _NotificationCard(message: message, type: type),
          ),
        );
      },
    );

    _activeEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      if (_activeEntry == entry) {
        if (entry.mounted) {
          entry.remove();
        }
        _activeEntry = null;
      }
    });
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.message, required this.type});

  final String message;
  final AppNotificationType type;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _backgroundColor(type),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor(type)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(_icon(type), color: _iconColor(type)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppPalette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _backgroundColor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.success:
        return AppPalette.success.withValues(alpha: 0.14);
      case AppNotificationType.error:
        return AppPalette.danger.withValues(alpha: 0.14);
      case AppNotificationType.warning:
        return AppPalette.warning.withValues(alpha: 0.16);
      case AppNotificationType.info:
        return AppPalette.primary.withValues(alpha: 0.14);
    }
  }

  static Color _borderColor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.success:
        return AppPalette.success.withValues(alpha: 0.32);
      case AppNotificationType.error:
        return AppPalette.danger.withValues(alpha: 0.32);
      case AppNotificationType.warning:
        return AppPalette.warning.withValues(alpha: 0.36);
      case AppNotificationType.info:
        return AppPalette.primary.withValues(alpha: 0.32);
    }
  }

  static Color _iconColor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.success:
        return AppPalette.success;
      case AppNotificationType.error:
        return AppPalette.danger;
      case AppNotificationType.warning:
        return AppPalette.warning;
      case AppNotificationType.info:
        return AppPalette.primary;
    }
  }

  static IconData _icon(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.success:
        return Icons.check_circle_outline_rounded;
      case AppNotificationType.error:
        return Icons.error_outline_rounded;
      case AppNotificationType.warning:
        return Icons.warning_amber_rounded;
      case AppNotificationType.info:
        return Icons.info_outline_rounded;
    }
  }
}

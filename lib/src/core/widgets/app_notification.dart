import 'dart:async';

import 'package:flutter/material.dart';

enum AppNotificationType { success, error, info, warning }

/// Shows a top-anchored snack-style notification.
///
/// Solid opaque background, theme-aware text, smooth slide+fade animation.
class AppNotifier {
  AppNotifier._();

  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) =>
      show(context, message: message, type: AppNotificationType.info, duration: duration);

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) =>
      show(context, message: message, type: AppNotificationType.success, duration: duration);

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) =>
      show(context, message: message, type: AppNotificationType.warning, duration: duration);

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) =>
      show(context, message: message, type: AppNotificationType.error, duration: duration);

  static void show(
    BuildContext context, {
    required String message,
    required AppNotificationType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    _dismissTimer?.cancel();
    if (_activeEntry?.mounted ?? false) {
      _activeEntry!.remove();
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        final topPad = MediaQuery.of(ctx).viewPadding.top;
        return Positioned(
          left: 16,
          right: 16,
          top: topPad + 12,
          child: _NotificationBanner(
            message: message,
            type: type,
            isDark: isDark,
            onDismiss: () {
              if (entry.mounted) entry.remove();
              if (_activeEntry == entry) _activeEntry = null;
            },
          ),
        );
      },
    );

    _activeEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      if (_activeEntry == entry) {
        if (entry.mounted) entry.remove();
        _activeEntry = null;
      }
    });
  }
}

class _NotificationBanner extends StatefulWidget {
  const _NotificationBanner({
    required this.message,
    required this.type,
    required this.isDark,
    required this.onDismiss,
  });

  final String message;
  final AppNotificationType type;
  final bool isDark;
  final VoidCallback onDismiss;

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _bgColor {
    if (widget.isDark) {
      return switch (widget.type) {
        AppNotificationType.success => const Color(0xFF1A3828),
        AppNotificationType.error   => const Color(0xFF3B1C1C),
        AppNotificationType.warning => const Color(0xFF3A2A0C),
        AppNotificationType.info    => const Color(0xFF0D2652),
      };
    } else {
      return switch (widget.type) {
        AppNotificationType.success => const Color(0xFFEBF9F0),
        AppNotificationType.error   => const Color(0xFFFBECEC),
        AppNotificationType.warning => const Color(0xFFFFF8E6),
        AppNotificationType.info    => const Color(0xFFE8F0FE),
      };
    }
  }

  Color get _accentColor => switch (widget.type) {
    AppNotificationType.success => const Color(0xFF2EAE63),
    AppNotificationType.error   => const Color(0xFFD64545),
    AppNotificationType.warning => const Color(0xFFE49B12),
    AppNotificationType.info    => const Color(0xFF0476FF),
  };

  Color get _textColor => widget.isDark
      ? const Color(0xFFF3F6FC)
      : const Color(0xFF1B1E2B);

  IconData get _icon => switch (widget.type) {
    AppNotificationType.success => Icons.check_circle_rounded,
    AppNotificationType.error   => Icons.error_rounded,
    AppNotificationType.warning => Icons.warning_rounded,
    AppNotificationType.info    => Icons.info_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  left: BorderSide(color: _accentColor, width: 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: widget.isDark ? 0.35 : 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Icon(_icon, color: _accentColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: _textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.close_rounded, size: 18, color: _textColor.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

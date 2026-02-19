import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Displays a compact account label/value row inside account cards.
class AccountDetailRow extends StatelessWidget {
  const AccountDetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text('$label:', style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}

/// Keeps `RefreshIndicator` compatible even for non-scroll body states.
class CenteredListBody extends StatelessWidget {
  const CenteredListBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.35),
        Center(child: child),
      ],
    );
  }
}

/// Renders compact metadata chips used in job preview/detail sheets.
class MetaPill extends StatelessWidget {
  const MetaPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppPalette.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppPalette.border),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

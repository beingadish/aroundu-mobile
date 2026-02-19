import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/job_item.dart';
import '../../../../core/theme/app_theme.dart';

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    this.showDistance = false,
    this.onTap,
  });

  final JobItem job;
  final bool showDistance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final due = DateFormat('dd MMM yyyy').format(job.dueDate);

    final body = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _StatusBadge(status: job.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            job.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(icon: Icons.category_outlined, label: job.category),
              _MetaChip(icon: Icons.location_on_outlined, label: job.location),
              _MetaChip(
                icon: Icons.currency_rupee,
                label: job.budget.toStringAsFixed(0),
              ),
              _MetaChip(icon: Icons.event_outlined, label: 'Due $due'),
              if (showDistance && job.distanceKm != null)
                _MetaChip(
                  icon: Icons.near_me_outlined,
                  label: '${job.distanceKm!.toStringAsFixed(1)} km',
                ),
            ],
          ),
        ],
      ),
    );

    return Card(
      child: onTap == null
          ? body
          : InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: body,
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppPalette.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

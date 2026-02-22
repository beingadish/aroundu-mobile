import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../auth/data/auth_api.dart';
import '../../review/view/review_list_view.dart';
import '../../review/view_model/review_view_model.dart';
import '../view_model/profile_view_model.dart';

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({
    super.key,
    required this.userId,
    required this.isWorker,
    this.userName,
  });

  final int userId;
  final bool isWorker;
  final String? userName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = isWorker
        ? ref.watch(publicWorkerProfileProvider(userId))
        : ref.watch(publicClientProfileProvider(userId));

    return Scaffold(
      appBar: AppBar(title: Text(userName ?? 'Profile')),
      body: profileAsync.when(
        loading: () => const LoadingState(message: 'Loading profile...'),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () {
            if (isWorker) {
              ref.invalidate(publicWorkerProfileProvider(userId));
            } else {
              ref.invalidate(publicClientProfileProvider(userId));
            }
          },
        ),
        data: (profile) => _ProfileContent(
          profile: profile,
          isWorker: isWorker,
          userId: userId,
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({
    required this.profile,
    required this.isWorker,
    required this.userId,
  });

  final UserProfileData profile;
  final bool isWorker;
  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Avatar + Name
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppPalette.primary.withValues(alpha: 0.1),
                backgroundImage:
                    profile.profileImageUrl != null &&
                        profile.profileImageUrl!.isNotEmpty
                    ? NetworkImage(profile.profileImageUrl!)
                    : null,
                child:
                    profile.profileImageUrl == null ||
                        profile.profileImageUrl!.isEmpty
                    ? Text(
                        (profile.name ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                profile.name ?? 'Unknown',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                isWorker ? 'Worker' : 'Client',
                style: TextStyle(
                  color: AppPalette.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Worker rating
        if (isWorker) ...[
          _WorkerRating(workerId: userId),
          const SizedBox(height: 16),
        ],

        // Info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (isWorker) ...[
                  _InfoRow(
                    icon: Icons.work_history_outlined,
                    label: 'Experience',
                    value: profile.experienceYears != null
                        ? '${profile.experienceYears} years'
                        : '—',
                  ),
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Certifications',
                    value: profile.certifications ?? '—',
                  ),
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.circle,
                    label: 'Availability',
                    value: profile.isOnDuty == true
                        ? 'Available'
                        : 'Unavailable',
                    valueColor: profile.isOnDuty == true
                        ? AppPalette.success
                        : AppPalette.textSecondary,
                  ),
                ] else ...[
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Member',
                    value: profile.name ?? '—',
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Reviews link
        if (isWorker)
          Card(
            child: ListTile(
              leading: const Icon(Icons.star_outline_rounded),
              title: const Text('View All Reviews'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WorkerReviewsScreen(
                      workerId: userId,
                      workerName: profile.name,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _WorkerRating extends ConsumerWidget {
  const _WorkerRating({required this.workerId});
  final int workerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(workerReviewsControllerProvider(workerId));

    return reviewsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        if (stats.totalReviews == 0) return const SizedBox.shrink();
        return Center(
          child: RatingStars(
            rating: stats.averageRating,
            size: 22,
            reviewCount: stats.totalReviews,
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppPalette.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: AppPalette.textSecondary, fontSize: 13),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: valueColor,
              fontSize: 13,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

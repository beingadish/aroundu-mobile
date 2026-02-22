import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/rating_stars.dart';
import '../model/review_models.dart';
import '../view_model/review_view_model.dart';

class WorkerReviewsScreen extends ConsumerWidget {
  const WorkerReviewsScreen({
    super.key,
    required this.workerId,
    this.workerName,
  });

  final int workerId;
  final String? workerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(workerReviewsControllerProvider(workerId));

    return Scaffold(
      appBar: AppBar(
        title: Text(workerName != null ? '$workerName\'s Reviews' : 'Reviews'),
      ),
      body: reviewsAsync.when(
        loading: () => const LoadingState(message: 'Loading reviews...'),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref
              .read(workerReviewsControllerProvider(workerId).notifier)
              .refresh(),
        ),
        data: (stats) {
          if (stats.reviews.isEmpty) {
            return const EmptyState(
              icon: Icons.rate_review_outlined,
              title: 'No reviews yet',
              subtitle: 'Reviews will appear here after completed tasks.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref
                .read(workerReviewsControllerProvider(workerId).notifier)
                .refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary card
                _ReviewSummaryCard(stats: stats),
                const SizedBox(height: 20),
                Text(
                  'All Reviews',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...stats.reviews.map(
                  (review) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReviewCard(review: review),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  const _ReviewSummaryCard({required this.stats});
  final ReviewStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              stats.averageRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: AppPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            RatingStars(
              rating: stats.averageRating,
              size: 28,
              showNumber: false,
            ),
            const SizedBox(height: 8),
            Text(
              '${stats.totalReviews} review${stats.totalReviews == 1 ? '' : 's'}',
              style: const TextStyle(
                color: AppPalette.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final ReviewItem review;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppPalette.primary.withValues(alpha: 0.1),
                  child: Text(
                    (review.reviewerName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppPalette.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName ?? 'Anonymous',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (review.createdAt != null)
                        Text(
                          DateFormat.yMMMd().format(review.createdAt!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppPalette.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                RatingStars(rating: review.rating, size: 16, showNumber: false),
              ],
            ),
            if (review.reviewComment != null &&
                review.reviewComment!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                review.reviewComment!,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

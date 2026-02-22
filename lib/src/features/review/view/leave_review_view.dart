import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/rating_stars.dart';
import '../view_model/review_view_model.dart';

class LeaveReviewScreen extends ConsumerStatefulWidget {
  const LeaveReviewScreen({
    super.key,
    required this.jobId,
    required this.workerName,
  });

  final int jobId;
  final String workerName;

  @override
  ConsumerState<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends ConsumerState<LeaveReviewScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = ref.read(
      submitReviewControllerProvider(widget.jobId).notifier,
    );
    notifier.setComment(_commentController.text);

    final success = await notifier.submit();

    if (!mounted) return;

    if (success) {
      AppNotifier.showSuccess(context, 'Thanks for your review!');
      Navigator.of(context).pop(true);
    } else {
      final errorMessage = ref
          .read(submitReviewControllerProvider(widget.jobId))
          .errorMessage;
      if (errorMessage != null) {
        AppNotifier.showError(context, errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(submitReviewControllerProvider(widget.jobId));

    return Scaffold(
      appBar: AppBar(title: const Text('Leave a Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 36,
              backgroundColor: AppPalette.primary.withValues(alpha: 0.1),
              child: Text(
                widget.workerName.isNotEmpty
                    ? widget.workerName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppPalette.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How was ${widget.workerName}?',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your feedback helps the community',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            InteractiveRatingStars(
              rating: reviewState.rating,
              onChanged: (rating) {
                ref
                    .read(submitReviewControllerProvider(widget.jobId).notifier)
                    .setRating(rating);
              },
              size: 44,
            ),
            const SizedBox(height: 8),
            Text(
              _ratingLabel(reviewState.rating),
              style: TextStyle(
                color: AppPalette.warning,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 1200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Share your experience (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Submit Review',
              isLoading: reviewState.isSubmitting,
              onPressed: reviewState.rating >= 1 ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(double rating) {
    if (rating >= 5) return 'Excellent!';
    if (rating >= 4) return 'Great!';
    if (rating >= 3) return 'Good';
    if (rating >= 2) return 'Fair';
    if (rating >= 1) return 'Poor';
    return 'Tap to rate';
  }
}

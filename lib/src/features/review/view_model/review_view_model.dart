import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../model/review_models.dart';

// ─────────────────── Worker Reviews ───────────────────

class WorkerReviewsController extends FamilyAsyncNotifier<ReviewStats, int> {
  @override
  Future<ReviewStats> build(int workerId) async {
    return _fetch(workerId);
  }

  Future<ReviewStats> _fetch(int workerId) async {
    final auth = ref.read(authControllerProvider);
    final reviewApi = ref.read(reviewApiProvider);

    final rawList = await reviewApi.getWorkerReviews(
      workerId: workerId,
      token: auth.token,
    );

    final reviews = rawList.map(ReviewItem.fromMap).toList();
    reviews.sort((a, b) {
      final aTime = a.createdAt ?? DateTime(2000);
      final bTime = b.createdAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    final totalRating = reviews.fold<double>(0, (sum, r) => sum + r.rating);
    final average = reviews.isEmpty ? 0.0 : totalRating / reviews.length;

    return ReviewStats(
      averageRating: average,
      totalReviews: reviews.length,
      reviews: reviews,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }
}

final workerReviewsControllerProvider =
    AsyncNotifierProvider.family<WorkerReviewsController, ReviewStats, int>(
      WorkerReviewsController.new,
    );

// ─────────────────── Submit Review ───────────────────

class SubmitReviewState {
  const SubmitReviewState({
    this.rating = 0,
    this.comment = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.isSubmitted = false,
  });

  final double rating;
  final String comment;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSubmitted;

  SubmitReviewState copyWith({
    double? rating,
    String? comment,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    bool? isSubmitted,
  }) {
    return SubmitReviewState(
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }
}

class SubmitReviewController extends FamilyNotifier<SubmitReviewState, int> {
  @override
  SubmitReviewState build(int jobId) {
    return const SubmitReviewState();
  }

  void setRating(double rating) {
    state = state.copyWith(rating: rating, clearError: true);
  }

  void setComment(String comment) {
    state = state.copyWith(comment: comment, clearError: true);
  }

  Future<bool> submit() async {
    if (state.rating < 1) {
      state = state.copyWith(errorMessage: 'Please select a rating');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final auth = ref.read(authControllerProvider);
      if (!auth.isAuthenticated || auth.userId == null) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'Please log in first',
        );
        return false;
      }

      final reviewApi = ref.read(reviewApiProvider);
      await reviewApi.submitReview(
        token: auth.token!,
        jobId: arg,
        clientId: auth.userId!,
        rating: state.rating,
        reviewComment: state.comment.isEmpty ? null : state.comment,
      );

      state = state.copyWith(isSubmitting: false, isSubmitted: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.toString(),
      );
      return false;
    }
  }
}

final submitReviewControllerProvider =
    NotifierProvider.family<SubmitReviewController, SubmitReviewState, int>(
      SubmitReviewController.new,
    );

// ─────────────────── Job Review (single) ───────────────────

final jobReviewProvider = FutureProvider.family<ReviewItem?, int>((
  ref,
  jobId,
) async {
  final auth = ref.read(authControllerProvider);
  final reviewApi = ref.read(reviewApiProvider);

  try {
    final raw = await reviewApi.getJobReview(jobId: jobId, token: auth.token);
    return ReviewItem.fromMap(raw);
  } catch (_) {
    // Job may not have a review yet
    return null;
  }
});

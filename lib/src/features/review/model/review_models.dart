class ReviewItem {
  const ReviewItem({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.reviewerId,
    this.reviewerName,
    required this.rating,
    this.reviewComment,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int jobId;
  final int workerId;
  final int reviewerId;
  final String? reviewerName;
  final double rating;
  final String? reviewComment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ReviewItem.fromMap(Map<String, dynamic> map) {
    return ReviewItem(
      id: _asInt(map['id']),
      jobId: _asInt(map['jobId']),
      workerId: _asInt(map['workerId']),
      reviewerId: _asInt(map['reviewerId']),
      reviewerName: map['reviewerName']?.toString(),
      rating: _asDouble(map['rating']),
      reviewComment: map['reviewComment']?.toString(),
      createdAt: _asDateTime(map['createdAt']),
      updatedAt: _asDateTime(map['updatedAt']),
    );
  }
}

class ReviewStats {
  const ReviewStats({
    this.averageRating = 0,
    this.totalReviews = 0,
    this.reviews = const <ReviewItem>[],
  });

  final double averageRating;
  final int totalReviews;
  final List<ReviewItem> reviews;
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _asDateTime(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

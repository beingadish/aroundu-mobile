class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final String? details;

  /// User-visible message with HTTP code/details when available.
  String get userMessage {
    final status = statusCode == null ? '' : ' (HTTP $statusCode)';
    final detailText = details?.trim();
    if (detailText == null || detailText.isEmpty) {
      return '$message$status';
    }
    return '$message$status: $detailText';
  }

  @override
  String toString() {
    final status = statusCode == null ? '' : ' (HTTP $statusCode)';
    final detail = details == null || details!.isEmpty ? '' : ': $details';
    return '$message$status$detail';
  }
}

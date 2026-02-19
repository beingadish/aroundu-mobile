import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum JobStatus { openForBids, inProgress, completed, cancelled }

extension JobStatusView on JobStatus {
  String get label {
    switch (this) {
      case JobStatus.openForBids:
        return 'Open For Bids';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case JobStatus.openForBids:
        return AppPalette.primary;
      case JobStatus.inProgress:
        return AppPalette.warning;
      case JobStatus.completed:
        return AppPalette.success;
      case JobStatus.cancelled:
        return AppPalette.danger;
    }
  }
}

class JobItem {
  const JobItem({
    this.jobId = 0,
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.budget,
    required this.createdAt,
    required this.dueDate,
    required this.status,
    this.statusCode = 'OPEN_FOR_BIDS',
    this.paymentMode,
    this.requiredSkillNames = const <String>[],
    this.distanceKm,
  });

  final int jobId;
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final double budget;
  final DateTime createdAt;
  final DateTime dueDate;
  final JobStatus status;
  final String statusCode;
  final String? paymentMode;
  final List<String> requiredSkillNames;
  final double? distanceKm;

  JobItem copyWith({
    int? jobId,
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    double? budget,
    DateTime? createdAt,
    DateTime? dueDate,
    JobStatus? status,
    String? statusCode,
    String? paymentMode,
    List<String>? requiredSkillNames,
    double? distanceKm,
  }) {
    return JobItem(
      jobId: jobId ?? this.jobId,
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      budget: budget ?? this.budget,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      statusCode: statusCode ?? this.statusCode,
      paymentMode: paymentMode ?? this.paymentMode,
      requiredSkillNames: requiredSkillNames ?? this.requiredSkillNames,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}

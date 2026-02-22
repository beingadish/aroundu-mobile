import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 20,
    this.showNumber = true,
    this.reviewCount,
  });

  final double rating;
  final double size;
  final bool showNumber;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          if (rating >= starValue) {
            return Icon(
              Icons.star_rounded,
              size: size,
              color: AppPalette.warning,
            );
          } else if (rating >= starValue - 0.5) {
            return Icon(
              Icons.star_half_rounded,
              size: size,
              color: AppPalette.warning,
            );
          } else {
            return Icon(
              Icons.star_outline_rounded,
              size: size,
              color: AppPalette.border,
            );
          }
        }),
        if (showNumber) ...[
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: size * 0.7,
              color: AppPalette.textPrimary,
            ),
          ),
        ],
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: size * 0.6,
              color: AppPalette.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class InteractiveRatingStars extends StatelessWidget {
  const InteractiveRatingStars({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 40,
  });

  final double rating;
  final ValueChanged<double> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = (index + 1).toDouble();
        return GestureDetector(
          onTap: () => onChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              rating >= starValue
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: size,
              color: rating >= starValue
                  ? AppPalette.warning
                  : AppPalette.border,
            ),
          ),
        );
      }),
    );
  }
}

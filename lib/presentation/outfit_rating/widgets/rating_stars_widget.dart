import 'package:flutter/material.dart';

/// Interactive star rating widget
/// Displays 5 stars that can be tapped to set a rating from 1-5
class RatingStarsWidget extends StatelessWidget {
  final int rating;
  final double size;
  final Function(int) onRatingChanged;

  const RatingStarsWidget({
    Key? key,
    required this.rating,
    this.size = 32.0,
    required this.onRatingChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () => onRatingChanged(starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Icon(
              starIndex <= rating ? Icons.star : Icons.star_border,
              size: size,
              color: starIndex <= rating
                  ? Colors.amber
                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        );
      }),
    );
  }
}

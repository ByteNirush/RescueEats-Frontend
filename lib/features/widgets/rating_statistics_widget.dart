import 'package:flutter/material.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';

class RatingStatisticsWidget extends StatelessWidget {
  final double averageRating;
  final int totalRatings;
  final Map<String, dynamic> ratingBreakdown;

  const RatingStatisticsWidget({
    super.key,
    required this.averageRating,
    required this.totalRatings,
    required this.ratingBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Ratings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Average Rating Display
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < averageRating.round()
                                ? Icons.star
                                : Icons.star_border,
                            color: AppColors.primary,
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$totalRatings ratings',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Rating Breakdown
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildRatingBar(
                        5,
                        ratingBreakdown['fiveStar'] ?? 0,
                        totalRatings,
                      ),
                      _buildRatingBar(
                        4,
                        ratingBreakdown['fourStar'] ?? 0,
                        totalRatings,
                      ),
                      _buildRatingBar(
                        3,
                        ratingBreakdown['threeStar'] ?? 0,
                        totalRatings,
                      ),
                      _buildRatingBar(
                        2,
                        ratingBreakdown['twoStar'] ?? 0,
                        totalRatings,
                      ),
                      _buildRatingBar(
                        1,
                        ratingBreakdown['oneStar'] ?? 0,
                        totalRatings,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$stars',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '$count',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

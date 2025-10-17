import 'package:flutter/material.dart';
import 'ratings_summary.dart'; // Import your RatingsSummary widget

class BestReview extends StatelessWidget {
  final List<Map<String, dynamic>> reviews;
  static const brandColor = Color(0xFFFF5200);
  const BestReview({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const SizedBox.shrink(); // No reviews
    }

    final bestReview = reviews[0]; // Assuming first is best

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Top Review",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to RatingsSummary
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RatingsSummary(),
                    ),
                  );
                },
                child: Text(
                  "See All Reviews",
                  style: TextStyle(
                    color: brandColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Review Card
          Card(
            elevation: 2,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(bestReview["rating"].toString()),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bestReview["title"] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(bestReview["comment"] as String),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

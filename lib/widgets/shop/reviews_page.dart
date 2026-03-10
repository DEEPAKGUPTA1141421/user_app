import 'package:flutter/material.dart';
import './mock_data.dart';
import './models.dart';
import './app_theme.dart';

class ReviewsPage extends StatelessWidget {
  final String shopId;
  const ReviewsPage({super.key, required this.shopId});

  @override
  Widget build(BuildContext context) {
    final shop = mockShops.firstWhere((s) => s.id == shopId, orElse: () => mockShops.first);
    final reviews = shop.reviews;

    final avgRating = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

    final ratingBreakdown = [5, 4, 3, 2, 1].map((star) {
      final count = reviews.where((r) => r.rating.round() == star).length;
      final pct = reviews.isEmpty ? 0 : (count / reviews.length * 100).round();
      return {'star': star, 'count': count, 'pct': pct};
    }).toList();

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shop.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: kTextPrimary)),
            Text('${reviews.length} reviews', style: const TextStyle(fontSize: 12, color: kTextMuted)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating overview card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customer Ratings & Reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTextPrimary)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Big rating
                      Column(
                        children: [
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: kTextPrimary),
                          ),
                          _buildStarRow(avgRating, size: 18),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatCount(shop.ratingCount)} ratings',
                            style: const TextStyle(fontSize: 12, color: kTextMuted),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Container(width: 1, height: 80, color: kBorder),
                      const SizedBox(width: 24),
                      // Bar breakdown
                      Expanded(
                        child: Column(
                          children: ratingBreakdown.map((item) {
                            final star = item['star'] as int;
                            final pct = item['pct'] as int;
                            final count = item['count'] as int;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Text('$star', style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct / 100,
                                        backgroundColor: const Color(0xFFF3F4F6),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          star >= 4 ? kGreen : star == 3 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                                        ),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 16,
                                    child: Text('$count', style: const TextStyle(fontSize: 11, color: kTextMuted)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Reviews list
            ...reviews.map((review) => _buildReviewCard(review)),

            const SizedBox(height: 20),

            // Write review CTA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPrimary, Color(0xFFFF9A3C)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  const Text('Share Your Experience', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Help others by writing a review for ${shop.name}', style: const TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: kPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Write a Review', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    final ratingColor = review.rating >= 4 ? kGreen : review.rating >= 3 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: kPrimary,
                child: Text(review.avatar, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(review.userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextPrimary)),
                        if (review.verified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, size: 14, color: kGreen),
                          const SizedBox(width: 2),
                          const Text('Verified', style: TextStyle(fontSize: 11, color: kGreen)),
                        ],
                      ],
                    ),
                    Text(review.date, style: const TextStyle(fontSize: 11, color: kTextMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ratingColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 12),
                    const SizedBox(width: 3),
                    Text(review.rating.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Review content
          Text(review.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary)),
          const SizedBox(height: 4),
          Text(review.body, style: const TextStyle(fontSize: 13, color: kTextSecondary, height: 1.5)),
          const SizedBox(height: 12),

          // Helpful
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Was this review helpful?', style: TextStyle(fontSize: 11, color: kTextMuted)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    const Icon(Icons.thumb_up_outlined, size: 14, color: kTextSecondary),
                    const SizedBox(width: 4),
                    Text('Yes (${review.helpfulCount})', style: const TextStyle(fontSize: 11, color: kTextSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarRow(double rating, {double size = 14}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return Icon(Icons.star, size: size, color: const Color(0xFFFBBF24));
        } else if (i < rating) {
          return Icon(Icons.star_half, size: size, color: const Color(0xFFFBBF24));
        } else {
          return Icon(Icons.star_border, size: size, color: const Color(0xFFD1D5DB));
        }
      }),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
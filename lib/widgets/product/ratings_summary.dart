import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../widgets/real_search_page.dart'; // Import your RealSearchPage

class RatingDistribution {
  final int stars;
  final int count;
  final int percentage;

  RatingDistribution({
    required this.stars,
    required this.count,
    required this.percentage,
  });
}

class TopReview {
  final int rating;
  final String category;
  final String date;
  final String text;
  final String author;
  final bool verified;
  final int helpful;
  final int unhelpful;
  final List<String> images;

  TopReview({
    required this.rating,
    required this.category,
    required this.date,
    required this.text,
    required this.author,
    required this.verified,
    required this.helpful,
    required this.unhelpful,
    required this.images,
  });
}

class RatingsSummary extends StatelessWidget {
  const RatingsSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final successColor = Colors.green;
    final mutedColor = Colors.grey.shade500;
    final secondaryColor = Colors.grey.shade200;
    const brandColor = Color(0xFFFF5200);
    final ratingDistribution = [
      RatingDistribution(stars: 5, count: 5785, percentage: 42),
      RatingDistribution(stars: 4, count: 3253, percentage: 24),
      RatingDistribution(stars: 3, count: 2251, percentage: 16),
      RatingDistribution(stars: 2, count: 984, percentage: 7),
      RatingDistribution(stars: 1, count: 1455, percentage: 11),
    ];

    final features = [
      "Fabric Quality",
      "Colour",
      "Style",
      "Comfort",
      "True to size"
    ];

    final topReviews = [
      TopReview(
        rating: 4,
        category: "Value-for-money",
        date: "2 years ago",
        text: "Satisfied",
        author: "Juhi Bhattacharya",
        verified: true,
        helpful: 87,
        unhelpful: 18,
        images: [
          "https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=150&h=200&fit=crop",
          "https://images.unsplash.com/photo-1594633313593-bab3825d0caf?w=150&h=200&fit=crop"
        ],
      ),
      TopReview(
        rating: 5,
        category: "Best in the market!",
        date: "2 years ago",
        text: "Omg...😍 I'm in love with this top this looks so good",
        author: "Flipka..., Patna",
        verified: true,
        helpful: 28,
        unhelpful: 4,
        images: [],
      ),
      TopReview(
        rating: 5,
        category: "Best in the market!",
        date: "2 years ago",
        text: "Omg...😍 I'm in love with this top this looks so good",
        author: "Flipka..., Patna",
        verified: true,
        helpful: 28,
        unhelpful: 4,
        images: [],
      ),
      TopReview(
        rating: 5,
        category: "Best in the market!",
        date: "2 years ago",
        text: "Omg...😍 I'm in love with this top this looks so good",
        author: "Flipka..., Patna",
        verified: true,
        helpful: 28,
        unhelpful: 4,
        images: [],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          readOnly: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RealSearchPage()),
            );
          },
          decoration: InputDecoration(
            hintText: "Search for products",
            filled: true,
            fillColor: Colors.grey[200],
            prefixIcon: const Icon(CupertinoIcons.search, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Ratings and reviews",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Icon(CupertinoIcons.chevron_down, size: 20),
              ],
            ),
            const SizedBox(height: 16),

            // Rating Summary
            Row(
              children: [
                const Text("3.8",
                    style:
                        TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Icon(CupertinoIcons.star_fill, size: 24, color: successColor),
                const SizedBox(width: 8),
                Text("Good",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: successColor)),
              ],
            ),
            const SizedBox(height: 4),
            Text("based on 13,728 ratings by ✓ Verified Buyers",
                style: TextStyle(fontSize: 13, color: mutedColor)),
            const SizedBox(height: 16),

            // Features Customers Loved
            const Text("Features customers loved",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                )),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: features.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(features[index],
                      style: const TextStyle(fontSize: 12, color: brandColor)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Rating Distribution
            Column(
              children: ratingDistribution.map((rating) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text("${rating.stars}",
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 2),
                      Icon(CupertinoIcons.star_fill,
                          size: 12, color: successColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: secondaryColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: rating.percentage / 100,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: successColor,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(rating.count.toString(),
                          style: TextStyle(fontSize: 12, color: mutedColor)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Top Reviews
            Column(
              children: topReviews.map((review) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.only(bottom: 12),
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            final filled = i < review.rating;
                            return Icon(CupertinoIcons.star_fill,
                                size: 16,
                                color: filled ? successColor : mutedColor);
                          }),
                          const SizedBox(width: 8),
                          Text("${review.rating}.0",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          Text(review.category,
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (review.images.isNotEmpty)
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: review.images.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, idx) => ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(review.images[idx],
                                  width: 60, height: 80, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      if (review.images.isNotEmpty) const SizedBox(height: 8),
                      Text(review.text, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(review.author,
                                  style: TextStyle(
                                      fontSize: 12, color: mutedColor)),
                              const SizedBox(width: 6),
                              if (review.verified)
                                Text("✓ Verified Buyer",
                                    style: TextStyle(
                                        fontSize: 12, color: mutedColor)),
                            ],
                          ),
                          Text(review.date,
                              style:
                                  TextStyle(fontSize: 12, color: mutedColor)),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

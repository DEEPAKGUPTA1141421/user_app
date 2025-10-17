import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class Review {
  final int id;
  final int rating;
  final String title;
  final String reviewFor;
  final String comment;
  final String author;
  final int helpful;
  final int unhelpful;
  final bool verified;
  final String date;
  final List<String>? images;

  Review({
    required this.id,
    required this.rating,
    required this.title,
    required this.reviewFor,
    required this.comment,
    required this.author,
    required this.helpful,
    required this.unhelpful,
    required this.verified,
    required this.date,
    this.images,
  });
}

class ReviewCard extends StatelessWidget {
  final Review review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final successColor = Colors.green;
    final mutedColor = Colors.grey.shade500;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0)), // border-border
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ⭐ Rating Row
          Row(
            children: [
              ...List.generate(5, (i) {
                final filled = i < review.rating;
                return Icon(
                  CupertinoIcons.star_fill,
                  size: 16,
                  color: filled ? successColor : mutedColor,
                  fill: filled ? 1.0 : 0.0,
                );
              }),
              const SizedBox(width: 8),
              Text(
                "${review.rating}.0",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text("•"),
              ),
              Text(
                review.title,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Review For
          Text(
            "Review for: ${review.reviewFor}",
            style: TextStyle(fontSize: 13, color: mutedColor),
          ),

          const SizedBox(height: 8),

          // Comment
          Text(
            review.comment,
            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 10),

          // Review Images
          if (review.images != null && review.images!.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.images!.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    review.images![index],
                    width: 100,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Author + Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Author Name
              Text(
                review.author,
                style: TextStyle(color: mutedColor, fontSize: 13),
              ),

              // Helpful / Unhelpful Buttons
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      side: BorderSide(color: theme.dividerColor),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 32),
                    ),
                    icon:
                        const Icon(CupertinoIcons.hand_thumbsup_fill, size: 14),
                    label: Text(
                      "Helpful for ${review.helpful}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      shape: const CircleBorder(),
                      side: BorderSide(color: theme.dividerColor),
                      minimumSize: const Size(36, 36),
                    ),
                    child: const Icon(CupertinoIcons.hand_thumbsdown_fill,
                        size: 14),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Verified + Date
          Row(
            children: [
              if (review.verified) ...[
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: successColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Verified Purchase",
                      style: TextStyle(
                        fontSize: 13,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text("•"),
                  ],
                ),
              ],
              const SizedBox(width: 4),
              Text(
                review.date,
                style: TextStyle(fontSize: 13, color: mutedColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

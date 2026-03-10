import 'package:flutter/material.dart';
import './models.dart';
import './app_theme.dart';

class ShopCard extends StatelessWidget {
  final Shop shop;
  final VoidCallback onTap;

  const ShopCard({super.key, required this.shop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    shop.image,
                    height: 176,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 176,
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(Icons.store, color: Colors.grey, size: 48),
                    ),
                  ),
                ),
                // Gradient overlay with offer
                if (shop.offer != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xBF000000)],
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.zero),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.percent, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              shop.offer!,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Category badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      shop.category,
                      style: const TextStyle(fontSize: 11, color: kTextSecondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTextPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shop.description,
                    style: const TextStyle(fontSize: 12, color: kTextSecondary, height: 1.4),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Rating
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: kGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 12),
                            const SizedBox(width: 3),
                            Text(
                              shop.rating.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${_formatCount(shop.ratingCount)})',
                        style: const TextStyle(fontSize: 12, color: kTextSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Distance & Delivery
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: kPrimary),
                      const SizedBox(width: 4),
                      Text(shop.distance, style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: kTextMuted)),
                      const SizedBox(width: 8),
                      Text(shop.deliveryTime, style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: shop.tags.take(3).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.label_outline, size: 10, color: kTextMuted),
                          const SizedBox(width: 3),
                          Text(tag, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
                        ],
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
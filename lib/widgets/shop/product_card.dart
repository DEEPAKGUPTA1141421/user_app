import 'package:flutter/material.dart';
import './models.dart';
import './app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '₹${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    return '₹${price.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  product.image,
                  height: 144,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 144,
                    color: const Color(0xFFF3F4F6),
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              ),
              if (product.badge != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.badge!,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              if (product.discountPercent != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${product.discountPercent}% off',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontSize: 13, color: kTextPrimary, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Rating
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: kGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${_formatCount(product.ratingCount)})',
                      style: const TextStyle(color: kTextMuted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Price
                Row(
                  children: [
                    Text(
                      _formatPrice(product.price),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextPrimary),
                    ),
                    if (product.originalPrice != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        _formatPrice(product.originalPrice!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: kTextMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                // Add to Cart Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.shopping_cart_outlined, size: 14),
                    label: const Text('Add', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimary,
                      side: const BorderSide(color: kPrimary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
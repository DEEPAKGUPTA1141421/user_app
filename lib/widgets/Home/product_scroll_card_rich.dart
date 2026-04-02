// lib/widgets/Home/product_scroll_card_rich.dart
// A richer product card for PRODUCT_SCROLL sections that shows
// price, discount, rating, and a gradient-background variant.

import 'package:flutter/material.dart';
import '../../model/section_model.dart';

const Color _kBrand = Color(0xFFFF5200);

/// Full-featured product scroll card with price overlay, discount badge,
/// and configurable background from section item metadata.
class ProductScrollCardRich extends StatelessWidget {
  final SectionItem item;
  final VoidCallback onTap;

  const ProductScrollCardRich({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = item.meta;
    final bg = meta.background;
    final isGradient = meta.colorType == ColorType.gradient;
    final hasImage = meta.imageUrl != null && !meta.imageUrl!.contains('localimage');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: isGradient ? null : bg,
          gradient: isGradient
              ? LinearGradient(
                  colors: [bg, bg.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area with discount badge ─────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: hasImage
                        ? Image.network(meta.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),
                  ),
                ),
                if (meta.showDiscount && meta.filter?.type == 'percent' && meta.filter!.discount != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kBrand,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${meta.filter!.discount}% off',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Text info ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (meta.showName && meta.name != null)
                    Text(
                      meta.name!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (meta.showDescription && meta.description != null)
                    Text(
                      meta.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (meta.showRating)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, size: 10, color: Colors.white),
                              SizedBox(width: 2),
                              Text('4.2', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('(1.2k)', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                      ],
                    ),
                  if (meta.showPrice && meta.filter?.gte != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '₹${meta.filter!.gte!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _kBrand,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.grey),
      ),
    );
  }
}

// ─── ONE-ROW HERO CARD (for PRODUCT_SCROLL with columns=1, large height) ─────
// Shows a single wide product card per row — like the "Iconic Deals" section
class ProductHeroCard extends StatelessWidget {
  final SectionItem item;
  final VoidCallback onTap;

  const ProductHeroCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = item.meta;
    final hasImage = meta.imageUrl != null && !meta.imageUrl!.contains('localimage');
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth - 48,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: meta.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 120,
                height: 120,
                child: hasImage
                    ? Image.network(meta.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.itemType == ItemType.BRAND)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kBrand.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BRAND OFFER',
                          style: TextStyle(fontSize: 9, color: _kBrand, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (meta.name != null)
                      Text(
                        meta.name!,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    if (meta.description != null)
                      Text(
                        meta.description!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    if (meta.filter?.gte != null)
                      Text(
                        'From ₹${meta.filter!.gte!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _kBrand,
                        ),
                      ),
                    if (meta.filter?.discount != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Min ${meta.filter!.discount}% off',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade100,
        child: const Icon(Icons.shopping_bag_outlined, size: 36, color: Colors.grey),
      );
}
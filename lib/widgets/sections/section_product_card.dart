import 'package:flutter/material.dart';
import '../../model/section_v2.dart';
import '../../utils/app_colors.dart';

// ProductCard for backend-driven sections.
// Variants: standard | compact | highlight | spec
class SectionProductCard extends StatelessWidget {
  final SectionItemV2 item;
  final String variant; // standard | compact | highlight
  final bool showDiscount;
  final bool showRating;
  final bool showBadge;
  final bool showPriceStrikethrough;
  final double? width;
  final VoidCallback? onTap;

  const SectionProductCard({
    super.key,
    required this.item,
    this.variant = 'standard',
    this.showDiscount = true,
    this.showRating = false,
    this.showBadge = true,
    this.showPriceStrikethrough = true,
    this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case 'compact':
        return _CompactCard(item: item, width: width, showDiscount: showDiscount, onTap: onTap);
      case 'highlight':
        return _HighlightCard(item: item, width: width, showPriceStrikethrough: showPriceStrikethrough, onTap: onTap);
      default:
        return _StandardCard(
          item: item,
          showDiscount: showDiscount,
          showRating: showRating,
          showBadge: showBadge,
          onTap: onTap,
        );
    }
  }
}

// ─── Standard card ─────────────────────────────────────────────────────────────
class _StandardCard extends StatelessWidget {
  final SectionItemV2 item;
  final bool showDiscount;
  final bool showRating;
  final bool showBadge;
  final VoidCallback? onTap;
  const _StandardCard({
    required this.item,
    required this.showDiscount,
    required this.showRating,
    required this.showBadge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    final imageUrl = item.imageUrl ?? '';
    final title = item.title ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 55,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Container(
                      width: double.infinity,
                      color: AppColors.surface2,
                      child: imageUrl.isNotEmpty
                          ? Image.network(imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder())
                          : _placeholder(),
                    ),
                  ),
                  if (showBadge && (p?.isBestseller == true))
                    const Positioned(
                      top: 6,
                      left: 6,
                      child: _Badge('BESTSELLER', Colors.orange),
                    ),
                  if (showDiscount && p != null && p.discountPct > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _Badge('${p.discountPct}% off',
                          const Color(0xFFFF5200)),
                    ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 45,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white,
                            height: 1.3)),
                    const Spacer(),
                    if (showRating && p?.avgRating != null)
                      _RatingRow(rating: p!.avgRating!, count: p.ratingCount),
                    if (p != null) ...[
                      const SizedBox(height: 3),
                      _PriceRow(
                        salePrice: p.priceRupees,
                        originalPrice: p.originalPriceRupees,
                        showStrikethrough:
                            showDiscount && p.discountPct > 0,
                      ),
                    ],
                    if (item.reason != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(item.reason!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.green)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Compact card (for rails) ──────────────────────────────────────────────────
class _CompactCard extends StatelessWidget {
  final SectionItemV2 item;
  final double? width;
  final bool showDiscount;
  final VoidCallback? onTap;
  const _CompactCard(
      {required this.item,
      this.width,
      required this.showDiscount,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    final imageUrl = item.imageUrl ?? '';
    final title = item.title ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: AppColors.surface2,
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),
                  ),
                ),
                if (showDiscount && p != null && p.discountPct > 0)
                  Positioned(
                    top: 5,
                    left: 5,
                    child: _Badge('${p.discountPct}%', const Color(0xFFFF5200)),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white,
                          height: 1.3)),
                  if (p != null) ...[
                    const SizedBox(height: 4),
                    Text('₹${p.priceRupees.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Highlight card ────────────────────────────────────────────────────────────
class _HighlightCard extends StatelessWidget {
  final SectionItemV2 item;
  final double? width;
  final bool showPriceStrikethrough;
  final VoidCallback? onTap;
  const _HighlightCard(
      {required this.item,
      this.width,
      required this.showPriceStrikethrough,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    final imageUrl = item.imageUrl ?? '';
    final title = item.title ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Taller image (4:5 ratio approx)
            Expanded(
              flex: 60,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(14)),
                    child: Container(
                      width: double.infinity,
                      color: AppColors.surface2,
                      child: imageUrl.isNotEmpty
                          ? Image.network(imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder())
                          : _placeholder(),
                    ),
                  ),
                  if (p != null && p.discountPct > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _Badge('${p.discountPct}% OFF',
                          const Color(0xFFFF5200)),
                    ),
                ],
              ),
            ),
            // Info — heavier typography
            Expanded(
              flex: 40,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                            height: 1.3)),
                    const Spacer(),
                    if (p != null)
                      _PriceRow(
                        salePrice: p.priceRupees,
                        originalPrice: p.originalPriceRupees,
                        showStrikethrough:
                            showPriceStrikethrough && p.discountPct > 0,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style: const TextStyle(
              fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  final int? count;
  const _RatingRow({required this.rating, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 12, color: AppColors.green),
        const SizedBox(width: 3),
        Text(rating.toStringAsFixed(1),
            style: const TextStyle(
                fontSize: 10, color: AppColors.grey, fontWeight: FontWeight.w600)),
        if (count != null)
          Text(' ($count)',
              style:
                  const TextStyle(fontSize: 9, color: AppColors.grey)),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final double salePrice;
  final double originalPrice;
  final bool showStrikethrough;
  const _PriceRow(
      {required this.salePrice,
      required this.originalPrice,
      required this.showStrikethrough});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('₹${salePrice.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.white)),
        if (showStrikethrough && originalPrice > salePrice) ...[
          const SizedBox(width: 5),
          Text('₹${originalPrice.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.grey,
                  decoration: TextDecoration.lineThrough)),
        ],
      ],
    );
  }
}

Widget _placeholder() => const Center(
      child: Icon(Icons.shopping_bag_outlined, size: 32, color: AppColors.grey),
    );

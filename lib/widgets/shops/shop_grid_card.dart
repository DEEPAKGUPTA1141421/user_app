import 'package:flutter/material.dart';
import '../../model/shop.dart';
import '../../utils/app_colors.dart';

class ShopGridCard extends StatelessWidget {
  final Shop shop;
  final VoidCallback onTap;

  const ShopGridCard({super.key, required this.shop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // ── Image ──────────────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: SizedBox(
                width: 80,
                height: 80,
                child: _ShopImage(shop: shop),
              ),
            ),
            const SizedBox(width: 12),

            // ── Info ───────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Name + open badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          shop.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _OpenBadge(isOpen: shop.isOpen),
                    ],
                  ),

                  const SizedBox(height: 3),

                  // Category · city
                  Text(
                    shop.categoryName != null
                        ? '${shop.categoryName} · ${shop.city}'
                        : shop.city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Stats row
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFFC107)),
                      const SizedBox(width: 2),
                      Text(
                        shop.avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      _dot(),
                      const Icon(Icons.near_me_outlined, size: 11, color: AppColors.greyDark),
                      const SizedBox(width: 2),
                      Text(
                        shop.distanceLabel,
                        style: const TextStyle(color: AppColors.grey, fontSize: 11),
                      ),
                      _dot(),
                      const Icon(Icons.schedule_outlined, size: 11, color: AppColors.greyDark),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          shop.deliveryEtaLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.grey, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Text('·', style: TextStyle(color: AppColors.greyDark, fontSize: 11)),
      );
}

// ── Image with letter fallback ────────────────────────────────────────────────

class _ShopImage extends StatelessWidget {
  final Shop shop;
  const _ShopImage({required this.shop});

  @override
  Widget build(BuildContext context) {
    final url = shop.logoUrl ?? (shop.images.isNotEmpty ? shop.images.first : null);
    if (url != null) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _LetterPlaceholder(initial: shop.initial),
      );
    }
    return _LetterPlaceholder(initial: shop.initial);
  }
}

class _LetterPlaceholder extends StatelessWidget {
  final String initial;
  const _LetterPlaceholder({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface2,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Open/Closed badge ─────────────────────────────────────────────────────────

class _OpenBadge extends StatelessWidget {
  final bool isOpen;
  const _OpenBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFF0F2E1A) : AppColors.surface2,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isOpen ? const Color(0xFF1E6B3A) : AppColors.border,
        ),
      ),
      child: Text(
        isOpen ? 'OPEN' : 'CLOSED',
        style: TextStyle(
          color: isOpen ? const Color(0xFF4CAF50) : AppColors.greyDark,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

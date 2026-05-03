import 'package:flutter/material.dart';
import '../../model/shop.dart';
import '../../utils/app_colors.dart';

class ShopCard extends StatefulWidget {
  final Shop shop;
  final VoidCallback onTap;

  const ShopCard({super.key, required this.shop, required this.onTap});

  @override
  State<ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<ShopCard> {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  List<String> get _images {
    if (widget.shop.images.isNotEmpty) return widget.shop.images;
    if (widget.shop.logoUrl != null) return [widget.shop.logoUrl!];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image carousel ─────────────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: images.isEmpty
                    ? _InitialsBanner(initial: widget.shop.initial)
                    : Stack(
                        children: [
                          PageView.builder(
                            controller: _pageCtrl,
                            itemCount: images.length,
                            onPageChanged: (i) =>
                                setState(() => _page = i),
                            itemBuilder: (_, i) => Image.network(
                              images[i],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  _InitialsBanner(
                                      initial: widget.shop.initial),
                            ),
                          ),
                          // Open/Closed badge (top-right overlay)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: _OpenBadge(isOpen: widget.shop.isOpen),
                          ),
                          // Dot indicators (bottom-center overlay)
                          if (images.length > 1)
                            Positioned(
                              bottom: 8,
                              left: 0,
                              right: 0,
                              child: _DotIndicators(
                                count: images.length,
                                current: _page,
                              ),
                            ),
                        ],
                      ),
              ),
            ),

            // ── Shop details ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row (with badge if no image — badge already in carousel overlay otherwise)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.shop.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (images.isEmpty) ...[
                        const SizedBox(width: 8),
                        _OpenBadge(isOpen: widget.shop.isOpen),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Category · city
                  Text(
                    widget.shop.categoryName != null
                        ? '${widget.shop.categoryName} · ${widget.shop.city}'
                        : widget.shop.city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Container(height: 1, color: AppColors.divider),
                  const SizedBox(height: 8),

                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFFFC107),
                        label: widget.shop.avgRating.toStringAsFixed(1),
                      ),
                      _dot(),
                      _StatChip(
                        icon: Icons.near_me_outlined,
                        label: widget.shop.distanceLabel,
                      ),
                      _dot(),
                      _StatChip(
                        icon: Icons.schedule_outlined,
                        label: widget.shop.deliveryEtaLabel,
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
        padding: EdgeInsets.symmetric(horizontal: 5),
        child: Text(
          '·',
          style: TextStyle(color: AppColors.greyDark, fontSize: 11),
        ),
      );
}

// ── Carousel sub-widgets ──────────────────────────────────────────────────────

class _InitialsBanner extends StatelessWidget {
  final String initial;
  const _InitialsBanner({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface2,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 48,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DotIndicators extends StatelessWidget {
  final int count;
  final int current;
  const _DotIndicators({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? AppColors.white
                : AppColors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen
            ? const Color(0xFF0F2E1A)
            : Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOpen ? const Color(0xFF1E6B3A) : AppColors.border,
        ),
      ),
      child: Text(
        isOpen ? 'OPEN' : 'CLOSED',
        style: TextStyle(
          color: isOpen ? const Color(0xFF4CAF50) : AppColors.greyDark,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  const _StatChip({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: iconColor ?? AppColors.grey),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// lib/widgets/Home/section_widget.dart  (FINAL — copy this entire file)
//
// Usage:
//   SectionWidget(section: section, onNavigate: (route, params) { ... })
//
// The factory reads section.type and section.config to decide layout:
//
//   CATEGORY      → horizontal chip scroll (circle images, name, description)
//   PRODUCT_SCROLL
//     columns==1  → hero wide-card scroll (like "Iconic Deals")
//     columns>=2  → compact square-card scroll (like "Suggested for You")
//   PRODUCT_GRID  → static N-column grid (no horizontal scroll)
//   BRAND         → circle logo scroll, supports gradient bg per item
//   BANNER        → full-width clickable image card
//   SPONSORED     → same as PRODUCT_SCROLL

import 'package:flutter/material.dart';
import '../../model/section_model.dart';
import 'product_scroll_card_rich.dart';

const Color kBrand = Color(0xFFFF5200);

// ─── Factory ─────────────────────────────────────────────────────────────────
class SectionWidget extends StatelessWidget {
  final Section section;
  final void Function(String route, Map<String, String> params)? onNavigate;

  const SectionWidget({super.key, required this.section, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    if (!section.active || section.items.isEmpty) return const SizedBox.shrink();

    switch (section.type) {
      case SectionType.CATEGORY:
        return _CategorySection(section: section, onNavigate: onNavigate);
      case SectionType.PRODUCT_SCROLL:
      case SectionType.SPONSORED:
        return section.config.columns == 1
            ? _ProductHeroScrollSection(section: section, onNavigate: onNavigate)
            : _ProductScrollSection(section: section, onNavigate: onNavigate);
      case SectionType.PRODUCT_GRID:
        return _ProductGridSection(section: section, onNavigate: onNavigate);
      case SectionType.BRAND:
        return _BrandSection(section: section, onNavigate: onNavigate);
      case SectionType.BANNER:
        return _BannerSection(section: section, onNavigate: onNavigate);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── CATEGORY Section ─────────────────────────────────────────────────────────
class _CategorySection extends StatelessWidget {
  final Section section;
  final void Function(String, Map<String, String>)? onNavigate;
  const _CategorySection({required this.section, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      section: section,
      child: SizedBox(
        height: 130,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: section.items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) => _CategoryChip(
            item: section.items[i],
            onTap: () {
              final item = section.items[i];
              final params = item.meta.filter?.toQueryParams() ?? {};
              if (item.itemRefId != null) params['refId'] = item.itemRefId!;
              onNavigate?.call('/category/${item.itemRefId ?? ''}', params);
            },
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final SectionItem item;
  final VoidCallback onTap;
  const _CategoryChip({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = item.meta;
    final bg = meta.background;
    final isLight = ThemeData.estimateBrightnessForColor(bg) == Brightness.light;
    final fg = isLight ? Colors.black87 : Colors.white;
    final hasImage = meta.imageUrl != null && !meta.imageUrl!.contains('localimage');

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 84,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: bg.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: ClipOval(
                child: hasImage
                    ? Image.network(meta.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _initials(meta.name, bg, fg))
                    : _initials(meta.name, bg, fg),
              ),
            ),
            const SizedBox(height: 5),
            if (meta.showName && meta.name != null)
              Text(meta.name!, maxLines: 2, textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500)),
            if (meta.showDescription && meta.description != null)
              Text(meta.description!, maxLines: 1, textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9.5, color: Colors.green.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _initials(String? name, Color bg, Color fg) => Container(
        color: bg,
        alignment: Alignment.center,
        child: Text(name != null && name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: fg)),
      );
}

// ─── PRODUCT_SCROLL – HERO (columns=1) ────────────────────────────────────────
// One wide card per item — like "Iconic Deals" in your data
class _ProductHeroScrollSection extends StatelessWidget {
  final Section section;
  final void Function(String, Map<String, String>)? onNavigate;
  const _ProductHeroScrollSection({required this.section, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      section: section,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: section.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ProductHeroCard(
                item: item,
                onTap: () => _nav(item),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _nav(SectionItem item) {
    final params = item.meta.filter?.toQueryParams() ?? {};
    if (item.itemType == ItemType.BRAND) {
      onNavigate?.call('/brand/${item.itemRefId ?? ''}', params);
    } else if (item.itemType == ItemType.CATEGORY) {
      onNavigate?.call('/category/${item.itemRefId ?? ''}', params);
    } else if (item.itemRefId != null && item.itemRefId != 'tobefilled') {
      onNavigate?.call('/productDetail/${item.itemRefId}', params);
    } else {
      onNavigate?.call('/search', params);
    }
  }
}

// ─── PRODUCT_SCROLL – COMPACT (columns>=2) ────────────────────────────────────
class _ProductScrollSection extends StatelessWidget {
  final Section section;
  final void Function(String, Map<String, String>)? onNavigate;
  const _ProductScrollSection({required this.section, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      section: section,
      child: SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: section.items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => ProductScrollCardRich(
            item: section.items[i],
            onTap: () {
              final item = section.items[i];
              final params = item.meta.filter?.toQueryParams() ?? {};
              if (item.itemRefId != null && item.itemRefId != 'tobefilled') {
                onNavigate?.call('/productDetail/${item.itemRefId}', params);
              } else {
                onNavigate?.call('/search', params);
              }
            },
          ),
        ),
      ),
    );
  }
}

// ─── PRODUCT_GRID Section ──────────────────────────────────────────────────────
class _ProductGridSection extends StatelessWidget {
  final Section section;
  final void Function(String, Map<String, String>)? onNavigate;
  const _ProductGridSection({required this.section, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final columns = section.config.columns.clamp(1, 3);
    return _SectionContainer(
      section: section,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: section.items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.70,
        ),
        itemBuilder: (_, i) => _ProductGridCard(
          item: section.items[i],
          onTap: () {
            final item = section.items[i];
            final params = item.meta.filter?.toQueryParams() ?? {};
            if (item.itemRefId != null && item.itemRefId != 'tobefilled') {
              onNavigate?.call('/productDetail/${item.itemRefId}', params);
            } else {
              onNavigate?.call('/search', params);
            }
          },
        ),
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final SectionItem item;
  final VoidCallback onTap;
  const _ProductGridCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = item.meta;
    final hasImage = meta.imageUrl != null && !meta.imageUrl!.contains('localimage');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + discount overlay
            Expanded(
              flex: 55,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: SizedBox(
                      width: double.infinity,
                      child: hasImage
                          ? Image.network(meta.imageUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder())
                          : _placeholder(),
                    ),
                  ),
                  if (meta.showDiscount &&
                      meta.filter?.type == 'percent' &&
                      meta.filter?.discount != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text('${meta.filter!.discount}% OFF',
                            style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 45,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (meta.showName && meta.name != null)
                      Text(meta.name!, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.2)),
                    const Spacer(),
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
                                Icon(Icons.star_rounded, size: 9, color: Colors.white),
                                SizedBox(width: 2),
                                Text('4.2', style: TextStyle(fontSize: 9, color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    if (meta.showPrice && meta.filter?.gte != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('₹${meta.filter!.gte!.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kBrand)),
                      ),
                    if (meta.showDescription && meta.description != null)
                      Text(meta.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: Colors.green.shade700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade50,
        child: const Center(child: Icon(Icons.shopping_bag_outlined, size: 32, color: Colors.grey)),
      );
}

// ─── BRAND Section ────────────────────────────────────────────────────────────
class _BrandSection extends StatelessWidget {
  final Section section;
  final void Function(String, Map<String, String>)? onNavigate;
  const _BrandSection({required this.section, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      section: section,
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: section.items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final item = section.items[i];
            final meta = item.meta;
            final hasImage = meta.imageUrl != null && !meta.imageUrl!.contains('localimage');
            final isGradient = meta.colorType == ColorType.gradient;

            return GestureDetector(
              onTap: () {
                final params = meta.filter?.toQueryParams() ?? {};
                onNavigate?.call('/brand/${item.itemRefId ?? ''}', params);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isGradient
                          ? LinearGradient(
                              colors: [meta.background, meta.background.withOpacity(0.5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isGradient ? null : meta.background,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: hasImage
                        ? ClipOval(child: Image.network(meta.imageUrl!, fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _brandInitial(meta.name)))
                        : _brandInitial(meta.name),
                  ),
                  const SizedBox(height: 5),
                  if (meta.showName && meta.name != null)
                    SizedBox(
                      width: 68,
                      child: Text(meta.name!, textAlign: TextAlign.center, maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500)),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _brandInitial(String? name) => Center(
        child: Text(name != null && name.isNotEmpty ? name[0].toUpperCase() : 'B',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      );
}

// ─── BANNER Section ───────────────────────────────────────────────────────────
class _BannerSection extends StatefulWidget {
  final Section section;
  final void Function(String, Map<String, String>)? onNavigate;
  const _BannerSection({required this.section, this.onNavigate});

  @override
  State<_BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends State<_BannerSection>
    with SingleTickerProviderStateMixin {
  late final PageController _pageCtrl;
  late final AnimationController _progressCtrl;
  int _current = 0;

  // Time each banner stays visible before auto-advancing
  static const Duration _holdDuration = Duration(seconds: 7);
  static const Duration _pageDuration = Duration(milliseconds: 400);

  List<SectionItem> get _items => widget.section.items;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _progressCtrl = AnimationController(vsync: this, duration: _holdDuration);

    if (_items.length > 1) {
      _progressCtrl.addStatusListener((status) {
        if (status == AnimationStatus.completed) _advance();
      });
      _progressCtrl.forward();
    }
  }

  void _advance() {
    if (!mounted || _items.length <= 1) return;
    final next = (_current + 1) % _items.length;
    _pageCtrl.animateToPage(next,
        duration: _pageDuration, curve: Curves.easeInOut);
  }

  void _onPageChanged(int i) {
    setState(() => _current = i);
    // Restart the progress bar for the new page
    _progressCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final height = (screenWidth * 0.45).clamp(160.0, 210.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          // ── Banner PageView (swipe to navigate) ───────────────────────────
          SizedBox(
            height: height,
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: _items.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (_, i) => _BannerCard(
                item: _items[i],
                onTap: () => widget.onNavigate
                    ?.call('/banner/${_items[i].itemRefId ?? ''}', {}),
              ),
            ),
          ),

          // ── Progress indicators ───────────────────────────────────────────
          if (_items.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 14, right: 14),
              child: Row(
                children: List.generate(_items.length, (i) {
                  final isActive = i == _current;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: i == 0 ? 0 : 4,
                          right: i == _items.length - 1 ? 0 : 4),
                      child: _ProgressBar(
                        isActive: isActive,
                        progress: isActive ? _progressCtrl : null,
                        isPast: i < _current,
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Progress Bar indicator ────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final bool isActive;
  final bool isPast;
  final AnimationController? progress;

  const _ProgressBar({
    required this.isActive,
    required this.isPast,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    const h = 3.5;
    const radius = BorderRadius.all(Radius.circular(2));
    const trackColor = Color(0xFFDDDDDD);
    const fillColor = Color(0xFF1A1A1A);

    // Past slide → fully filled
    if (isPast) {
      return Container(
          height: h,
          decoration: const BoxDecoration(
              color: fillColor, borderRadius: radius));
    }

    // Future slide → empty track
    if (!isActive) {
      return Container(
          height: h,
          decoration: const BoxDecoration(
              color: trackColor, borderRadius: radius));
    }

    // Active slide → animated fill
    return AnimatedBuilder(
      animation: progress!,
      builder: (_, __) => Stack(
        children: [
          // Track
          Container(
              height: h,
              decoration: const BoxDecoration(
                  color: trackColor, borderRadius: radius)),
          // Fill
          FractionallySizedBox(
            widthFactor: progress!.value,
            child: Container(
                height: h,
                decoration: const BoxDecoration(
                    color: fillColor, borderRadius: radius)),
          ),
        ],
      ),
    );
  }
}

// ── Banner Card ───────────────────────────────────────────────────────────────
class _BannerCard extends StatelessWidget {
  final SectionItem item;
  final VoidCallback onTap;

  const _BannerCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = item.meta;
    final hasImage =
        meta.imageUrl != null && !meta.imageUrl!.contains('localimage');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: meta.background,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: hasImage
              ? Image.network(
                  meta.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => _fallback(meta),
                )
              : _fallback(meta),
        ),
      ),
    );
  }

  Widget _fallback(SectionItemMeta meta) => Container(
        color: meta.background,
        alignment: Alignment.center,
        child: Text(
          item.meta.name ?? '',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
}

// ─── Shared Section Container ─────────────────────────────────────────────────
class _SectionContainer extends StatelessWidget {
  final Section section;
  final Widget child;
  const _SectionContainer({required this.section, required this.child});

  @override
  Widget build(BuildContext context) {
    final cfg = section.config;
    final isGradient = cfg.colorType == ColorType.gradient;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(section: section),
        child,
        const SizedBox(height: 10),
      ],
    );

    if (isGradient && cfg.firstHalf != null && cfg.secondHalf != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cfg.firstHalf!, cfg.secondHalf!],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: content,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: cfg.background,
      child: content,
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final Section section;
  const _SectionHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    if (section.title.isEmpty) return const SizedBox(height: 8);

    final cfg = section.config;
    final bgBrightness = ThemeData.estimateBrightnessForColor(cfg.background);
    final onDark = cfg.colorType == ColorType.gradient || bgBrightness == Brightness.dark;
    final titleColor = onDark ? Colors.white : const Color(0xFF1A1A1A);
    final accentColor = onDark ? Colors.white70 : kBrand;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              section.title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: titleColor),
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: accentColor),
        ],
      ),
    );
  }
}
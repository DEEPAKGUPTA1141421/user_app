import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/category_sections.dart';
import '../../provider/banner_provider.dart';
import '../responsive_banner_carousel.dart';
import './section_wrapper.dart';
import './product_card.dart';

class CategoryPage extends ConsumerStatefulWidget {
  final String? categoryId;
  const CategoryPage({super.key, required this.categoryId});

  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage> {
  // Sentinel so we distinguish "never fetched" from "fetched with null categoryId"
  static const String _never = '__NEVER__';
  String _lastKey = _never;

  @override
  void initState() {
    super.initState();
    // Defer past the first frame so Riverpod providers are mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerFetch(widget.categoryId);
    });
  }

  @override
  void didUpdateWidget(CategoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ React to every categoryId change from parent
    if (oldWidget.categoryId != widget.categoryId) {
      _triggerFetch(widget.categoryId);
    }
  }

  void _triggerFetch(String? categoryId) {
    final key = categoryId ?? '__NULL__';
    if (_lastKey == key) return; // same category — skip
    _lastKey = key;

    debugPrint('🔄 CategoryPage._triggerFetch → categoryId=$categoryId');

    // 1. Sections (pass categoryId so correct endpoint is used)
    ref
        .read(categorySectionsProvider.notifier)
        .fetchSectionsOfCategory(categoryId: categoryId);

    // 2. Banners
    ref.read(bannerProvider.notifier).clearBanners();
    if (categoryId != null && categoryId.isNotEmpty) {
      ref.read(bannerProvider.notifier).fetchBannersByCategory(categoryId);
    }

    // 3. Brands
    final brandsId = (categoryId != null && categoryId.isNotEmpty)
        ? categoryId
        : '5d70fc95-8a6b-4d04-95e9-9620269ab15e'; // default fallback
    ref.read(categorySectionsProvider.notifier).fetchBrands(brandsId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categorySectionsProvider);
    final bannerState = ref.watch(bannerProvider);

    // Use fine-grained flags — not the coarse isLoading
    final sectionsLoading = state['sectionsLoading'] as bool? ?? false;
    final brandsLoading   = state['brandsLoading']   as bool? ?? false;
    final sectionsData    = state['sectionsData']     as List<dynamic>? ?? [];
    final brands          = state['brands']           as List<dynamic>? ?? [];
    final bannerIsLoading = bannerState['isLoading']  as bool? ?? false;
    final banners         = bannerState['banners']    as List<dynamic>? ?? [];

    // Full-page loader only before the very first sections response
    if (sectionsLoading && sectionsData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: Color(0xFFFF5200))),
      );
    }

    if (sectionsData.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sectionsData.map<Widget>((section) {
        final type  = (section['type']  ?? '').toString().toUpperCase();
        final title = (section['title'] ?? '').toString();
        final items = (section['items'] ?? []) as List<dynamic>;

        switch (type) {

          // ── Banner ────────────────────────────────────────────────────────
          case 'BANNER':
            if (bannerIsLoading) return _shimmerBanner();
            if (banners.isEmpty) return const SizedBox.shrink();
            return ResponsiveBannerCarousel(
              banners: banners,
              categoryId: widget.categoryId ?? '',
            );

          // ── Brand ─────────────────────────────────────────────────────────
          case 'BRAND':
            if (brandsLoading && brands.isEmpty) return _shimmerSection(title);
            if (brands.isEmpty) return const SizedBox.shrink();
            return SectionWrapper(
              title: title,
              variant: SectionVariant.primary,
              hasArrow: false,
              child: SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: brands.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ProductCard(
                    product: brands[i]['metadata'] ?? brands[i],
                    showDiscount: false,
                    section: section,
                  ),
                ),
              ),
            );

          // ── Product sections ──────────────────────────────────────────────
          case 'SPONSORED':
          case 'PRODUCT_SCROLL':
          case 'PRODUCT_GRID':
          case 'CATEGORY':
            if (items.isEmpty) return const SizedBox.shrink();
            return SectionWrapper(
              title: title,
              variant: SectionVariant.primary,
              hasArrow: false,
              child: SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ProductCard(
                    product: items[i]['metadata'] ?? {},
                    showDiscount: true,
                    section: section,
                  ),
                ),
              ),
            );

          default:
            return const SizedBox.shrink();
        }
      }).toList(),
    );
  }

  // ── Shimmer helpers ────────────────────────────────────────────────────────

  Widget _shimmerBanner() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _shimmerSection(String title) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, __) => Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
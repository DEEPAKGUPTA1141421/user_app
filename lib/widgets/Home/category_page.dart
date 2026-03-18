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
  // Track the last fetched categoryId to avoid duplicate calls
  String? _lastFetchedCategoryId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchDataForCategory(widget.categoryId));
  }

  // ✅ This is the key fix — called whenever the parent rebuilds with a new categoryId
  @override
  void didUpdateWidget(CategoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      _fetchDataForCategory(widget.categoryId);
    }
  }

  /// Central method to trigger all APIs for a given category
  Future<void> _fetchDataForCategory(String? categoryId) async {
    // Avoid duplicate fetches for same category
    if (_lastFetchedCategoryId == categoryId) return;
    _lastFetchedCategoryId = categoryId;

    // 1. Fetch sections for this category (or "For You" if null)
    ref
        .read(categorySectionsProvider.notifier)
        .fetchSectionsOfCategory(categoryId: categoryId);

    if (categoryId != null && categoryId.isNotEmpty) {
      // 2. Clear previous banners before fetching new ones
      ref.read(bannerProvider.notifier).clearBanners();

      // 3. Fetch banners for this category
      ref.read(bannerProvider.notifier).fetchBannersByCategory(categoryId);

      // 4. Fetch brands for this category
      ref.read(categorySectionsProvider.notifier).fetchBrands(categoryId);
    } else {
      // No category selected — clear banners and fetch default brands
      ref.read(bannerProvider.notifier).clearBanners();
      ref
          .read(categorySectionsProvider.notifier)
          .fetchBrands('5d70fc95-8a6b-4d04-95e9-9620269ab15e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categorySectionsProvider);
    final bannerState = ref.watch(bannerProvider);

    final isLoading = state['isLoading'] ?? false;
    final sectionsData = state['sectionsData'] as List<dynamic>? ?? [];
    final brands = state['brands'] as List<dynamic>? ?? [];
    final bannerIsLoading = bannerState['isLoading'] ?? false;
    final banners = bannerState['banners'] as List<dynamic>? ?? [];

    // Show a full-page loader only on the very first load
    if (isLoading && sectionsData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5200)),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sectionsData.map((section) {
          final type = section['type'] ?? '';
          final title = section['title'] ?? '';
          final items = section['items'] ?? [];
          final config = section['config'] ?? {};

          switch (type.toUpperCase()) {
            case 'BANNER':
              // Show loading shimmer while banners are fetching
              if (bannerIsLoading) {
                return _BannerShimmer();
              }

              if (banners.isEmpty) {
                return const SizedBox.shrink();
              }

              return ResponsiveBannerCarousel(
                banners: banners,
                categoryId: widget.categoryId ?? '',
              );

            case 'BRAND':
              // Show shimmer while brands load
              if (isLoading && brands.isEmpty) {
                return _BrandShimmer(title: title);
              }

              return SectionWrapper(
                title: title,
                variant: SectionVariant.primary,
                hasArrow: false,
                child: SizedBox(
                  height: 160,
                  child: brands.isEmpty
                      ? const Center(
                          child: Text('No brands found',
                              style: TextStyle(color: Colors.white70)),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: brands.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, index) {
                            final brand = brands[index];
                            return ProductCard(
                              product: brand['metadata'] ?? brand,
                              showDiscount: false,
                              section: section,
                            );
                          },
                        ),
                ),
              );

            case 'SPONSORED':
            case 'PRODUCT_SCROLL':
            case 'PRODUCT_GRID':
            case 'CATEGORY':
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
                    itemBuilder: (_, index) {
                      final product = items[index]['metadata'] ?? {};
                      return ProductCard(
                        product: product,
                        showDiscount: true,
                        section: section,
                      );
                    },
                  ),
                ),
              );

            default:
              return const SizedBox.shrink();
          }
        }).toList(),
      ),
    );
  }
}

// ── Shimmer widgets ────────────────────────────────────────────────────────────

class _BannerShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const _ShimmerEffect(),
    );
  }
}

class _BrandShimmer extends StatelessWidget {
  final String title;
  const _BrandShimmer({required this.title});

  @override
  Widget build(BuildContext context) {
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
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
                child: const _ShimmerEffect(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerEffect extends StatefulWidget {
  const _ShimmerEffect();

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0.0, 0.5, 1.0],
          colors: const [
            Color(0xFFE0E0E0),
            Color(0xFFF5F5F5),
            Color(0xFFE0E0E0),
          ],
        ).createShader(bounds),
        child: Container(color: Colors.white),
      ),
    );
  }
}
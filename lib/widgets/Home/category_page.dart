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
  @override
  void initState() {
    super.initState();
    print("Init the Category Page");
    // Fetch sections when widget initializes
    Future.microtask(() {
      print("fetch data of Category Page");
      ref.read(categorySectionsProvider.notifier).fetchSectionsOfCategory();
      print("catgoryid ${widget.categoryId}");
      if (widget.categoryId != null) {
        // Clear previous banners
        ref.read(bannerProvider.notifier).clearBanners();
        
        ref
            .read(categorySectionsProvider.notifier)
            .fetchBrands("5d70fc95-8a6b-4d04-95e9-9620269ab15e");
        
        // Fetch banners for this category
        ref
            .read(bannerProvider.notifier)
            .fetchBannersByCategory(widget.categoryId!);
      }
    });
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

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5200)),
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
          final columns = config['columns'] ?? 1;

          switch (type.toUpperCase()) {
            case 'BANNER':
              // Show responsive banner carousel with API data
              if (bannerIsLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF5200)),
                  ),
                );
              }
              
              if (banners.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return ResponsiveBannerCarousel(
                banners: banners,
                categoryId: widget.categoryId ?? '',
              );

            case 'BRAND':
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
                    itemBuilder: (_, index) {
                      final brand = brands[index];
                      return ProductCard(
                        product: brand['metadata'] ?? brand,
                        showDiscount: false,
                        section:section
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

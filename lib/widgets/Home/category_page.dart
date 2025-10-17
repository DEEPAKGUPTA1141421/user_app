import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/category_sections.dart'; // adjust the path
import '../banner_section.dart';
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
      ref.read(categorySectionsProvider.notifier).fetchSectionsOfCategory();
      if (widget.categoryId != null) {
        ref
            .read(categorySectionsProvider.notifier)
            .fetchBrands("5d70fc95-8a6b-4d04-95e9-9620269ab15e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categorySectionsProvider);
    final isLoading = state['isLoading'] ?? false;
    final sectionsData = state['sectionsData'] as List<dynamic>? ?? [];
    final brands = state['brands'] as List<dynamic>? ?? [];

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5200)),
      );
    }

    if (sectionsData.isEmpty) {
      return const Center(child: Text("No sections found"));
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
              return BannerSection(section: section);

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

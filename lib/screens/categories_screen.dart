import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './categories/category_card.dart';
import './categories/category_section.dart';
import './categories/category_sidebar.dart';
import './categories/brand_section.dart';
import '../provider/category_sections.dart';
import 'package:flutter/foundation.dart';

const brandColor = Color(0xFFFF5200);

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String activeCategory = 'for-you';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // ✅ Fetch initial category and brand data
      await ref
          .read(categorySectionsProvider.notifier)
          .fetchCategories(true, "SUPER_CATEGORY");
      await ref
          .read(categorySectionsProvider.notifier)
          .fetchBrands('5d70fc95-8a6b-4d04-95e9-9620269ab15e');
    });
  }

  void handleCategoryClick(String categoryId) {
    setState(() {
      activeCategory = categoryId;
    });
    ref.read(categorySectionsProvider.notifier).fetchBrands(categoryId);
  }

  Future<void> _refresh() async {
    await ref
        .read(categorySectionsProvider.notifier)
        .fetchCategories(true, "SUPER_CATEGORY");
    await ref
        .read(categorySectionsProvider.notifier)
        .fetchBrands(activeCategory);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categorySectionsProvider);
    final bool isLoading = state['isLoading'] ?? false;
    final List<dynamic> brandData = state['brands'] ?? [];
    final List<dynamic> categories = state['categoryData'] ?? [];

    if (kDebugMode) {
      print(
          "✅ Rendering Categories Screen with ${categories.length} top categories");
    }

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          CategorySidebar(
            activeCategory: activeCategory,
            onCategoryClick: handleCategoryClick,
          ),

          // Main Content
          Expanded(
            child: RefreshIndicator(
              color: brandColor,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 16, top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔸 Brand Section
                    if (isLoading)
                      const BrandShimmerSkeleton(title: 'Brands You Like')
                    else
                      BrandSection(
                        title: 'Brands You Like',
                        brands: brandData.map((b) {
                          return BrandItem(
                            id: b['id'] ?? '',
                            name: b['name'] ?? 'Unknown',
                            logo: b['logoUrl'] ?? '',
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 16),

                    // 🔸 Dynamic Categories Rendering
                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(color: brandColor),
                        ),
                      )
                    else if (categories.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text("No categories available"),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var parent in categories) ...[
                            for (var category
                                in (parent['children'] ?? [])) ...[
                              CategorySection(
                                title: category['name'] ?? 'Untitled Category',
                                items: (category['children'] ?? [])
                                    .map<CategoryItem>((sub) => CategoryItem(
                                          id: sub['id'] ?? '',
                                          title: sub['name'] ?? 'Unnamed',
                                          image: sub['imageurl'] ??
                                              'https://picsum.photos/200?random=${sub['id']}',
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ],
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

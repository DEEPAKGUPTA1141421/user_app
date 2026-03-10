import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../provider/category_provider.dart'; // adjust path

class CategorySection extends ConsumerStatefulWidget {
  final Function(String) onCategorySelected;
  const CategorySection({super.key, required this.onCategorySelected});

  @override
  ConsumerState<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends ConsumerState<CategorySection> {
  int activeIndex = 0; // track selected category
  final double iconSize = 26;
  final Color brandColor = const Color(0xFFFF5200);

  @override
  Widget build(BuildContext context) {
    print("rendering category section");
    final state = ref.watch(categoryProvider);
    final isLoading = state['isLoading'] ?? false;
    final categories = state['categoryData'] as List<dynamic>? ?? [];
    print("rendering category section for debug ${categories.length}");
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: isLoading
              ? List.generate(6, (index) => _buildSkeleton())
              : List.generate(categories.length, (index) {
                  final cat = categories[index];
                  final isActive = activeIndex == index;
                  final name = cat['name'] ?? '';
                  final displayName =
                      name.length > 14 ? '${name.substring(0, 14)}...' : name;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        activeIndex = index; // update active category
                      });
                      widget.onCategorySelected(cat['id'].toString());
                      debugPrint("Selected category: ${cat['name']}");
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: brandColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.category, // placeholder icon
                              size: iconSize,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            displayName,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                          if (isActive)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              height: 3,
                              width: 30,
                              decoration: BoxDecoration(
                                color: brandColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 50,
              height: 12,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../provider/category_provider.dart';
import '../utils/app_colors.dart';

class CategorySection extends ConsumerStatefulWidget {
  final Function(String) onCategorySelected;

  const CategorySection({super.key, required this.onCategorySelected});

  @override
  ConsumerState<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends ConsumerState<CategorySection> {
  int activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryProvider);
    final isLoading = state['isLoading'] ?? false;
    final categories = state['categoryData'] as List<dynamic>? ?? [];

    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: isLoading
              ? List.generate(6, (index) => _buildSkeleton())
              : List.generate(categories.length, (index) {
                  final cat = categories[index];
                  final isActive = activeIndex == index;

                  final name = cat['name'] ?? '';
                  final image = cat['imageUrl'] ?? '';

                  final displayName =
                      name.length > 12 ? '${name.substring(0, 12)}…' : name;

                  return GestureDetector(
                    onTap: () {
                      setState(() => activeIndex = index);
                      widget.onCategorySelected(cat['id'].toString());
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          // 🔥 CATEGORY ICON (IMAGE BASED)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.white
                                  : AppColors.surface2,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.white
                                    : AppColors.border,
                                width: isActive ? 1.5 : 1,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.1),
                                        blurRadius: 8,
                                      )
                                    ]
                                  : [],
                            ),
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: Image.network(
                                image,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.category_outlined,
                                  color: AppColors.grey,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // 🔥 CATEGORY NAME
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isActive
                                  ? AppColors.white
                                  : AppColors.grey,
                            ),
                          ),

                          // 🔥 ACTIVE INDICATOR (Flipkart style)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(top: 4),
                            height: 2,
                            width: isActive ? 24 : 0,
                            decoration: BoxDecoration(
                              color: AppColors.white,
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

  /// 🔥 DARK THEME SKELETON
  Widget _buildSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Shimmer.fromColors(
        baseColor: AppColors.surface2,
        highlightColor: AppColors.surface,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 50,
              height: 10,
              color: AppColors.surface,
            ),
          ],
        ),
      ),
    );
  }
}
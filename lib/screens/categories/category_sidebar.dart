import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../provider/category_sections.dart';

class CategorySidebar extends ConsumerWidget {
  static const Color brandColor = Color(0xFFFF5200);
  final String activeCategory;
  final Function(String) onCategoryClick;

  const CategorySidebar({
    super.key,
    required this.activeCategory,
    required this.onCategoryClick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categorySectionsProvider);
    final isLoading = state['isLoading'] ?? false;
    final categories = state['categoryData'] as List<dynamic>? ?? [];

    return Container(
      width: 80,
      color: Colors.grey[200],
      child: isLoading
          ? _buildShimmerSidebar()
          : ListView(
              padding: const EdgeInsets.all(8),
              children: categories.map((category) {
                final id = category['id'] ?? '';
                final label = category['name'] ?? 'Unnamed';
                final isActive = activeCategory == id;

                return GestureDetector(
                  onTap: () => onCategoryClick(id),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? brandColor.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey.shade400,
                          radius: 28,
                          child: Text(
                            label.isNotEmpty ? label[0] : '?',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isActive ? brandColor : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  // Shimmer effect for sidebar
  Widget _buildShimmerSidebar() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  radius: 28,
                ),
                const SizedBox(height: 4),
                Container(
                  height: 10,
                  width: 50,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

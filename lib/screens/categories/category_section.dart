import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'category_card.dart';

class CategoryItem {
  final String id;
  final String title;
  final String image;

  CategoryItem({
    required this.id,
    required this.title,
    required this.image,
  });
}

class CategorySection extends StatefulWidget {
  final String title;
  final List<CategoryItem> items;
  final int initialCount;

  const CategorySection({
    super.key,
    required this.title,
    required this.items,
    this.initialCount = 6,
  });

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  bool showAll = false;

  @override
  Widget build(BuildContext context) {
    final displayItems = showAll
        ? widget.items
        : widget.items.take(widget.initialCount).toList();

    final hasMore = widget.items.length > widget.initialCount;

    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 Section title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: displayItems.length + (hasMore ? 1 : 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, // 🔥 better density like Amazon
              crossAxisSpacing: 10,
              mainAxisSpacing: 14,
              mainAxisExtent: 110,
            ),
            itemBuilder: (context, index) {
              // 🔥 View All Button
              if (hasMore && index == displayItems.length) {
                return GestureDetector(
                  onTap: () => setState(() => showAll = !showAll),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface2,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(
                          showAll
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 30,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        showAll ? "Less" : "More",
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final item = displayItems[index];

              return CategoryCard(
                title: item.title,
                image: item.image, // ✅ imageUrl used
              );
            },
          ),
        ],
      ),
    );
  }
}
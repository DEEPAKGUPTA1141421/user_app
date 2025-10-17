import 'package:flutter/material.dart';
import 'category_card.dart';

class CategoryItem {
  final String id;
  final String title;
  final String image;

  CategoryItem({required this.id, required this.title, required this.image});
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
    const brandColor = Color(0xFFFF5200);
    final displayItems = showAll
        ? widget.items
        : widget.items.take(widget.initialCount).toList();
    final hasMore = widget.items.length > widget.initialCount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0), // ✅ add safe spacing
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: SizedBox(
              width: 180, // ✅ allow wider titles
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // ✅ Wrap GridView in Padding and remove tight constraints
          GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayItems.length + (hasMore ? 1 : 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
              mainAxisExtent: 120, // ✅ add a bit more height
            ),
            itemBuilder: (context, index) {
              if (hasMore && index == displayItems.length) {
                return GestureDetector(
                  onTap: () => setState(() => showAll = !showAll),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: brandColor,
                        ),
                        child: Icon(
                          showAll ? Icons.expand_less : Icons.expand_more,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        showAll ? 'View Less' : 'View All',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final item = displayItems[index];
              return CategoryCard(title: item.title, image: item.image);
            },
          ),
        ],
      ),
    );
  }
}

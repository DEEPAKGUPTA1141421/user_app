import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class Category {
  final IconData icon;
  final String label;
  final bool active;
  Category({required this.icon, required this.label, required this.active});
}

class CategorySection extends StatefulWidget {
  const CategorySection({super.key});

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  int activeIndex = 0;

  final List<Map<String, dynamic>> categories = [
    {"icon": CupertinoIcons.bag, "label": "For You"},
    {"icon": CupertinoIcons.person, "label": "Fashion"},
    {"icon": CupertinoIcons.phone, "label": "Mobile"},
    {"icon": CupertinoIcons.desktopcomputer, "label": "Electronics"},
    {"icon": CupertinoIcons.bolt, "label": "Appliances"},
    {"icon": CupertinoIcons.star, "label": "Beauty"},
    {"icon": CupertinoIcons.house, "label": "Home"},
    {"icon": CupertinoIcons.sportscourt, "label": "Sports"},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(categories.length, (index) {
            final isActive = activeIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  activeIndex = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.blue
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        categories[index]["icon"],
                        size: 26,
                        color: isActive ? Colors.white : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      categories[index]["label"],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isActive ? Colors.blue : Colors.grey,
                      ),
                    ),
                    if (isActive)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 3,
                        width: 30,
                        decoration: BoxDecoration(
                          color: Colors.blue,
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
}

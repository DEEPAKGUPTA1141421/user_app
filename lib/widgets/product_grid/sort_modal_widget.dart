import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SortModalWidget extends StatelessWidget {
  final bool open;
  final ValueChanged<bool> onOpenChange;
  final String selectedSort;
  final ValueChanged<String> onSortChange;

  const SortModalWidget({
    super.key,
    required this.open,
    required this.onOpenChange,
    required this.selectedSort,
    required this.onSortChange,
  });

  static final sortOptions = [
    {'value': 'relevance', 'label': 'Relevance'},
    {'value': 'popularity', 'label': 'Popularity'},
    {'value': 'price-low', 'label': 'Price -- Low to High'},
    {'value': 'price-high', 'label': 'Price -- High to Low'},
    {'value': 'newest', 'label': 'Newest First'},
  ];

  @override
  Widget build(BuildContext context) {
    if (!open) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => onOpenChange(false),
      child: Container(
        color: Colors.black54,
        child: GestureDetector(
          onTap: () {}, // Prevent tap-through
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "SORT BY",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => onOpenChange(false),
                        child: const Icon(CupertinoIcons.xmark, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Radio options
                  Column(
                    children: sortOptions.map((option) {
                      final value = option['value']!;
                      final label = option['label']!;
                      return InkWell(
                        onTap: () => onSortChange(value),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: value,
                                groupValue: selectedSort,
                                onChanged: (v) => onSortChange(v!),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  label,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

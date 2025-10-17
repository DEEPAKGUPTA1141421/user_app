import 'package:flutter/material.dart';

class SizeSelector extends StatelessWidget {
  final List<String> sizes;
  final String selectedSize;
  final Color brandColor; // ✅ add this
  final Function(String) onSelectSize;

  const SizeSelector({
    Key? key,
    required this.sizes,
    required this.selectedSize,
    required this.onSelectSize,
    required this.brandColor, // ✅ required
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Size",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: sizes.map((size) {
            final isSelected = size == selectedSize;

            return GestureDetector(
              onTap: () => onSelectSize(size),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      isSelected ? brandColor.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? brandColor : borderColor,
                    width: 2,
                  ),
                ),
                child: Text(
                  size,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isSelected ? brandColor : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

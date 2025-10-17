import 'package:flutter/material.dart';

class ColorOption {
  final String name;
  final String image;

  ColorOption({required this.name, required this.image});
}

class ColorSelector extends StatelessWidget {
  final List<ColorOption> colors;
  final String selectedColor;
  final ValueChanged<String> onSelectColor;
  final Color brandColor; // pass your app's brandColor

  const ColorSelector({
    super.key,
    required this.colors,
    required this.selectedColor,
    required this.onSelectColor,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            "Select Color",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          height: 80, // fixed height like previous design
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final color = colors[index];
              final isSelected = color.name == selectedColor;

              return GestureDetector(
                onTap: () => onSelectColor(color.name),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(
                      color: isSelected ? brandColor : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(color.image),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

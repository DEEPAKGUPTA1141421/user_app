import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ProductHighlights extends StatefulWidget {
  final Map<String, String> highlights;

  const ProductHighlights({super.key, required this.highlights});

  @override
  State<ProductHighlights> createState() => _ProductHighlightsState();
}

class _ProductHighlightsState extends State<ProductHighlights> {
  int _visibleCount = 0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    for (int i = 0; i < widget.highlights.length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _visibleCount = i + 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mutedColor = Colors.white.withOpacity(0.8);
    final entries = widget.highlights.entries.toList();

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: const [
                Text(
                  "Key Features",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 18,
                  color: Colors.white70,
                ),
              ],
            ),
            const SizedBox(height: 20), // space between header and highlights

            // Animated Highlights
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_visibleCount, (index) {
                final entry = entries[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Key
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Value
                    Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Divider line
                    const Divider(
                      color: Colors.white30,
                      thickness: 1,
                      height: 1,
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

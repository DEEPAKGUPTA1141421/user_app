import 'package:flutter/material.dart';

class CategoryScroll extends StatelessWidget {
  const CategoryScroll({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // <-- return here
      height: 90, // Ensure this matches avatar + text height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 8,
        itemBuilder: (context, index) {
          return SizedBox(
            width: 70,
            child: Column(
              mainAxisSize: MainAxisSize.min, // prevents overflow
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.green,
                  child: Text("${index + 1}"),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    "Cat $index",
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

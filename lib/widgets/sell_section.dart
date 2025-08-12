import 'package:flutter/material.dart';

class SellSection extends StatelessWidget {
  const SellSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 8,
        itemBuilder: (context, index) {
          return SizedBox(
            width: 70,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Square logo with width: 48, height: 48
                Container(
                  width: 96,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.green,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
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

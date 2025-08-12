import 'package:flutter/material.dart';

class TitleRow extends StatelessWidget {
  final String title;
  const TitleRow({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Icon(Icons.arrow_forward, size: 20),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class CategoryPill extends StatelessWidget {
  final String name;
  final String icon;
  final Gradient gradient;

  const CategoryPill({
    super.key,
    required this.name,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/category/${name.toLowerCase()}');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, // w-16
            height: 64, // h-16
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16), // rounded-2xl
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 24), // text-2xl
              ),
            ),
          ),
          const SizedBox(height: 8), // gap-2
          Text(
            name,
            style: const TextStyle(
              fontSize: 12, // text-xs
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

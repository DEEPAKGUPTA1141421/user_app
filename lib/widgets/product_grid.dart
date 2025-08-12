import 'package:flutter/material.dart';

class ProductGrid extends StatelessWidget {
  final int itemCount;
  const ProductGrid({super.key, required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.7,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          color: Colors.teal.shade100,
          child: Center(child: Text("Product ${index + 1}")),
        );
      },
    );
  }
}

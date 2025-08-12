import 'package:flutter/material.dart';

class ProductList extends StatelessWidget {
  final int itemCount;
  const ProductList({super.key, required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            width: 140,
            margin: const EdgeInsets.all(8),
            color: Colors.purple.shade100,
            child: Center(child: Text("Product ${index + 1}")),
          );
        },
      ),
    );
  }
}

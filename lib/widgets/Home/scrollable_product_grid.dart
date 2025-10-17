import 'package:flutter/material.dart';
import './product_card.dart';

class ScrollableProductGrid extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final bool showDiscount;
  final int columns;

  const ScrollableProductGrid({
    super.key,
    required this.products,
    this.showDiscount = true,
    this.columns = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(),
      child: columns == 1
          ? SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return SizedBox(
                    width: 140,
                    child: ProductCard(
                      product: product,
                      showDiscount: showDiscount,
                    ),
                  );
                },
              ),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  showDiscount: showDiscount,
                );
              },
            ),
    );
  }
}

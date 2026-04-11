import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../provider/infinite_product_Provider.dart';

class InfiniteProductSection extends ConsumerStatefulWidget {
  const InfiniteProductSection({super.key});

  @override
  ConsumerState<InfiniteProductSection> createState() => _ProductSectionState();
}

class _ProductSectionState extends ConsumerState<InfiniteProductSection> {
  int page = 1;

  @override
  void initState() {
    super.initState();
    ref.read(InfiniteproductProvider.notifier).fetchProducts();
  }

  Widget _buildShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // ✅ no scroll conflict
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(InfiniteproductProvider);
    final products = state['products'] as List? ?? [];
    final isLoading = state['isLoading'] as bool? ?? false;
    final hasMore = state['hasMore'] as bool? ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            "Featured Products",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        if (products.isEmpty && isLoading) _buildShimmer(),
        GridView.builder(
          shrinkWrap: true, // ✅ prevents infinite height
          physics:
              const NeverScrollableScrollPhysics(), // ✅ disable scroll here
          itemCount: products.length + (hasMore ? 1 : 0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            if (index == products.length && hasMore) {
  // bottom shimmer loader
  ref.read(InfiniteproductProvider.notifier).fetchProducts(loadMore: true);
  return const Center( // Center widget added here
    child: Padding(
      padding: EdgeInsets.all(10.0),
      child: CircularProgressIndicator(
        color: Color(0xFFFF5200),
      ),
    ),
  );
}


            if (index >= products.length) return const SizedBox.shrink();

            final product = products[index];
            return _ProductCard(product: product);
          },
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final price = product['price'];
    final discountPrice = product['discountPrice'];
    final discountPercent =
        (((price - discountPrice) / price) * 100).toStringAsFixed(0);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.network(
                product['image'],
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹${discountPrice.toString()}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '₹${price.toString()}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$discountPercent% off',
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

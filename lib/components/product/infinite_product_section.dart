import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/infinite_product_Provider.dart';
import '../../utils/app_colors.dart';
import '../../core/widgets/app_loader.dart';
import '../../widgets/product/product_details_page.dart';

class InfiniteProductSection extends ConsumerStatefulWidget {
  const InfiniteProductSection({super.key});

  @override
  ConsumerState<InfiniteProductSection> createState() =>
      _ProductSectionState();
}

class _ProductSectionState extends ConsumerState<InfiniteProductSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(InfiniteproductProvider.notifier).fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(InfiniteproductProvider);
    final products = state.products;
    final isLoading = state.isLoading;
    final hasMore = state.hasMore;

    if (products.isEmpty && isLoading) {
      return _ShimmerGrid();
    }

    if (products.isEmpty && !isLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Text(
            'Popular Products',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.white),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: products.length + (hasMore ? 1 : 0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            if (index == products.length && hasMore) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref
                    .read(InfiniteproductProvider.notifier)
                    .fetchProducts(loadMore: true);
              });
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: AppSpinner(),
                ),
              );
            }
            if (index >= products.length) return const SizedBox.shrink();
            return _ProductCard(product: products[index]);
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductCard({required this.product});

  String get _id =>
      (product['id'] ?? product['productId'] ?? '').toString();

  String get _name =>
      product['name'] as String? ?? product['title'] as String? ?? '';

  String get _imageUrl =>
      product['imageurl'] as String? ??
      product['imageUrl'] as String? ??
      product['image'] as String? ??
      ((product['images'] as List?)?.firstOrNull as String? ?? '');

  double get _salePrice =>
      (product['salePrice'] ??
              product['discountPrice'] ??
              product['finalPrice'] ??
              product['price'] as num? ??
              0)
          .toDouble();

  double get _originalPrice =>
      (product['originalPrice'] ??
              product['price'] as num? ??
              _salePrice)
          .toDouble();

  int get _discountPct {
    final orig = _originalPrice;
    final sale = _salePrice;
    if (orig <= 0 || sale >= orig) return 0;
    return (((orig - sale) / orig) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _imageUrl.isNotEmpty;
    final pct = _discountPct;

    return GestureDetector(
      onTap: () {
        if (_id.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsPage(productId: _id),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 55,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Container(
                      width: double.infinity,
                      color: AppColors.surface2,
                      child: hasImage
                          ? Image.network(_imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder())
                          : _placeholder(),
                    ),
                  ),
                  if (pct > 0)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5200),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('$pct% off',
                            style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 45,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white,
                            height: 1.3)),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('₹${_salePrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white)),
                        if (pct > 0) ...[
                          const SizedBox(width: 5),
                          Text('₹${_originalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.grey,
                                  decoration: TextDecoration.lineThrough)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => const Center(
        child: Icon(Icons.shopping_bag_outlined,
            size: 32, color: AppColors.grey),
      );
}

class _ShimmerGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

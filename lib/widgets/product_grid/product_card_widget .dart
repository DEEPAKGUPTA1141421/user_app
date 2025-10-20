import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/product.dart';
import '../../provider/cart_provider.dart';
import '../product/product_details_page.dart';

class ProductCardWidget extends ConsumerStatefulWidget {
  final Product product;
  const ProductCardWidget({super.key, required this.product});

  @override
  ConsumerState<ProductCardWidget> createState() => _ProductCardWidgetState();
}

class _ProductCardWidgetState extends ConsumerState<ProductCardWidget> {
  bool isWishlisted = false;
final Color brandColor = const Color(0xFFFF5200); // Your brand color
  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    // Access cart state from Riverpod
    final cartState = ref.watch(cartProvider);
    final cartItems = cartState['cartData']?['items'] ?? [];
    final isInCart = cartItems.any((item) => item['productId'] == product.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(productId: product.id.toString()),
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight;

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    SizedBox(
                      height: maxHeight * 0.45,
                      child: Stack(
                        children: [
                          Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceVariant
                                .withOpacity(0.2),
                            padding: const EdgeInsets.all(12),
                            child: Image.network(
                              product.image,
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          ),
                          if (product.isBestseller ?? false)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'BESTSELLER',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Product Details
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.isSponsored ?? false)
                              Text(
                                "Sponsored",
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              product.name,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Pricing
                            Row(
                              children: [
                                Text(
                                  "↓${product.discount}%",
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    "₹${product.originalPrice.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    "₹${product.salePrice.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),

                            // Add to Cart Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isInCart
                                      ? Colors.grey
                                      : brandColor, // brand color
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  textStyle: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: () {
                                  if (isInCart) {
                                    ref
                                        .read(cartProvider.notifier)
                                        .removeItem(product.id.toString());
                                  } else {
                                    ref
                                        .read(cartProvider.notifier)
                                        .removeItem(product.id.toString());
                                  }
                                },
                                child: Text(isInCart ? "Added to Cart" : "Add to Cart"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Wishlist button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => isWishlisted = !isWishlisted),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        isWishlisted
                            ? CupertinoIcons.heart_solid
                            : CupertinoIcons.heart,
                        color: isWishlisted ? Colors.red : Colors.grey,
                        size: 18,
                      ),
                    ),
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

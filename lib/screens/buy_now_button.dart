// This file patches the Buy Now button behaviour in ProductDetailsPage.
// Drop this widget alongside the existing product_details_page.dart and
// call BuyNowButton wherever the "Buy Now" CTA appears.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/rider_provider.dart';
import '../provider/buy_now_provider.dart';
import 'buys/buy_now_address_sheet.dart';
import '../utils/app_colors.dart';

/// Drop-in replacement for the "Buy Now" CTA in ProductDetailsPage.
///
/// Usage (in the _BottomBar or wherever the Buy Now button is):
///   BuyNowButton(
///     productId: widget.productId,
///     variantId: variantId,
///     productName: name,
///     productImage: imageUrls.firstOrNull,
///     price: price,
///   )
class BuyNowButton extends ConsumerStatefulWidget {
  final String productId;
  final String variantId;
  final String productName;
  final String? productImage;
  final double price;
  final bool inStock;

  const BuyNowButton({
    super.key,
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.price,
    this.productImage,
    this.inStock = true,
  });

  @override
  ConsumerState<BuyNowButton> createState() => _BuyNowButtonState();
}

class _BuyNowButtonState extends ConsumerState<BuyNowButton> {
  bool _isLoading = false;

  Future<void> _handleBuyNow() async {
    if (!widget.inStock) return;
    if (widget.variantId.isEmpty) {
      _toast('Please select a variant');
      return;
    }

    setState(() => _isLoading = true);

    // Make sure user data (addresses) is loaded
    await ref.read(riderPod.notifier).getUserDetail();
    final addresses = ref.read(riderPod).addresses;

    if (!mounted) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = false);

    // If there's a default address, go straight to payment
    final defaultAddr = addresses.firstWhere(
      (a) => a['default'] == true,
      orElse: () => <String, dynamic>{},
    );

    if (defaultAddr.isNotEmpty) {
      _navigateToPayment(Map<String, dynamic>.from(defaultAddr as Map));
    } else if (addresses.isNotEmpty) {
      // Show address picker
      _showAddressPicker();
    } else {
      _toast('Please add a delivery address first');
      Navigator.pushNamed(context, '/account/addresses');
    }
  }

  void _showAddressPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BuyNowAddressSheet(
        onSelect: _navigateToPayment,
      ),
    );
  }

  void _navigateToPayment(Map<String, dynamic> address) {
    // Reset any previous Buy Now state
    ref.read(buyNowProvider.notifier).reset();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuyNowPaymentPage(
          productId: widget.productId,
          variantId: widget.variantId,
          productName: widget.productName,
          productImage: widget.productImage,
          price: widget.price,
          selectedAddress: address,
        ),
      ),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(color: AppColors.white, fontSize: 13)),
      backgroundColor: AppColors.surface2,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.inStock) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('Out of Stock',
              style: TextStyle(
                  color: AppColors.greyDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
      );
    }

    return GestureDetector(
      onTap: _isLoading ? null : _handleBuyNow,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _isLoading ? AppColors.surface2 : AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: AppColors.bg, strokeWidth: 2.5))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_rounded, color: AppColors.bg, size: 16),
                    SizedBox(width: 4),
                    Text('Buy Now',
                        style: TextStyle(
                            color: AppColors.bg,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Convenience bottom bar that wires Add to Cart + Buy Now together.
/// Replace the existing _BottomBar in product_details_page.dart with this.
class ProductActionBar extends ConsumerWidget {
  final bool isInCart;
  final bool inStock;
  final bool isAddingToCart;
  final VoidCallback? onAddToCart;
  final String productId;
  final String variantId;
  final String productName;
  final String? productImage;
  final double price;

  const ProductActionBar({
    super.key,
    required this.isInCart,
    required this.inStock,
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.price,
    this.productImage,
    this.isAddingToCart = false,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        child: inStock
            ? Row(
                children: [
                  // Add to Cart
                  Expanded(
                    child: GestureDetector(
                      onTap: isAddingToCart ? null : onAddToCart,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isInCart
                                ? AppColors.green
                                : AppColors.white,
                            width: 1.5,
                          ),
                        ),
                        child: isAddingToCart
                            ? const Center(
                                child: SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isInCart
                                        ? Icons.check_rounded
                                        : Icons.add_shopping_cart_rounded,
                                    color: isInCart
                                        ? AppColors.green
                                        : AppColors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isInCart ? 'In Cart' : 'Add to Cart',
                                    style: TextStyle(
                                        color: isInCart
                                            ? AppColors.green
                                            : AppColors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Buy Now
                  Expanded(
                    child: BuyNowButton(
                      productId: productId,
                      variantId: variantId,
                      productName: productName,
                      productImage: productImage,
                      price: price,
                      inStock: inStock,
                    ),
                  ),
                ],
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text('Out of Stock',
                      style: TextStyle(
                          color: AppColors.greyDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
              ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/cart_provider.dart';
import '../utils/app_colors.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(cartProvider.notifier).fetchCart());
  }

  Future<void> _refreshCart() async {
    ref.invalidate(cartProvider);
    await ref.read(cartProvider.notifier).fetchCart();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final isLoading = cartState['isLoading'] as bool? ?? false;
    final cartData = cartState['cartData'] as Map<String, dynamic>? ?? {};
    final items = (cartData['items'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("My Cart", style: TextStyle(color: AppColors.white)),
            Text(
              "${items.length} ${items.length == 1 ? 'item' : 'items'}",
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(CupertinoIcons.bag, color: AppColors.white),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: isLoading,
        child: Stack(
          children: [
            items.isEmpty && !isLoading
                ? _buildEmptyCart(context)
                : _buildCartList(context, cartData, items),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.cart, size: 70, color: AppColors.greyDark),
            const SizedBox(height: 16),
            const Text("Your cart is empty",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.white)),
            const SizedBox(height: 6),
            const Text("Add items to get started",
                style: TextStyle(color: AppColors.grey)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, "/home"),
              icon: const Icon(CupertinoIcons.square_grid_2x2, color: Colors.black),
              label: const Text("Browse Categories"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList(BuildContext context, Map<String, dynamic> cartData, List items) {
    // ✅ FIX: prices from API are already in rupees — no division needed
    final totalAmount = (cartData['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final totalDiscount = (cartData['totalDiscount'] as num?)?.toDouble() ?? 0.0;
    final gstCharge = (cartData['gstCharge'] as num?)?.toDouble() ?? 0.0;
    final serviceCharge = (cartData['serviceCharge'] as num?)?.toDouble() ?? 0.0;
    final deliveryCharge = (cartData['deliveryCharge'] as num?)?.toDouble() ?? 0.0;
    // ✅ FIX: API returns 'grandTotal' not 'grand_total'
    final grandTotal = (cartData['grandTotal'] as num?)?.toDouble() ?? totalAmount;

    return RefreshIndicator(
      onRefresh: _refreshCart,
      color: AppColors.white,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ✅ FIX: cast each item properly
                ...items.map((item) => _buildCartItem(item as Map<String, dynamic>)),
                const SizedBox(height: 16),

                // Price breakdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Price Details",
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
                      const SizedBox(height: 10),
                      _priceRow("Items Total", totalAmount),
                      if (totalDiscount > 0)
                        _priceRow("Discount", -totalDiscount, isDiscount: true),
                      if (gstCharge > 0)
                        _priceRow("GST", gstCharge),
                      if (serviceCharge > 0)
                        _priceRow("Service Charge", serviceCharge),
                      if (deliveryCharge > 0)
                        _priceRow("Delivery", deliveryCharge)
                      else
                        _priceRow("Delivery", 0, isFree: true),
                      const Divider(color: AppColors.divider),
                      _priceRow("Grand Total", grandTotal, isBold: true),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Checkout bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "₹${grandTotal.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (totalDiscount > 0)
                      Text(
                        "You save ₹${totalDiscount.toStringAsFixed(2)}",
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
                      ),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/order-summary'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                  ),
                  child: const Text("Checkout"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final quantity = item['quantity'] as int? ?? 1;
    // ✅ FIX: image can be null — use placeholder
    final imageUrl = item['image'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // ✅ FIX: null-safe image widget
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String? ?? 'Product',
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item['description'] != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        item['description'] as String,
                        style: const TextStyle(color: AppColors.grey, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      "₹${price.toStringAsFixed(2)}",
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // Quantity controls
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(CupertinoIcons.minus, size: 16, color: AppColors.white),
                            onPressed: quantity > 1
                                ? () => ref
                                    .read(cartProvider.notifier)
                                    .updateCartItem(item['id'] as String, quantity - 1)
                                : null,
                          ),
                          Text(quantity.toString(),
                              style: const TextStyle(color: AppColors.white)),
                          IconButton(
                            icon: const Icon(CupertinoIcons.plus, size: 16, color: AppColors.white),
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .updateCartItem(item['id'] as String, quantity + 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _actionButton("Remove", CupertinoIcons.delete, () {
                ref.read(cartProvider.notifier).removeItem(item['id'] as String);
              }),
              _actionButton("Save for later", CupertinoIcons.heart, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.shopping_bag_outlined, color: AppColors.greyDark, size: 28),
    );
  }

  Widget _actionButton(String text, IconData icon, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: AppColors.grey),
      label: Text(text, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
    );
  }

  Widget _priceRow(String title, double value,
      {bool isBold = false, bool isDiscount = false, bool isFree = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(title,
              style: TextStyle(
                  color: isBold ? AppColors.white : AppColors.grey,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          const Spacer(),
          isFree
              ? const Text("FREE",
                  style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13))
              : Text(
                  "${isDiscount ? '-' : ''}₹${value.abs().toStringAsFixed(2)}",
                  style: TextStyle(
                      color: isDiscount
                          ? Colors.greenAccent
                          : isBold
                              ? AppColors.white
                              : AppColors.grey,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
                ),
        ],
      ),
    );
  }
}
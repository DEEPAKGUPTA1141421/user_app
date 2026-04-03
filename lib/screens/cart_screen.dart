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
    final isLoading = cartState['isLoading'] as bool;
    final cartData = cartState['cartData'] ?? {};
    final items = (cartData['items'] ?? []) as List<dynamic>;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("My Cart",
                style: TextStyle(color: AppColors.white)),
            Text(
              "${items.length} ${items.length == 1 ? "item" : "items"}",
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            )
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(CupertinoIcons.bag, color: AppColors.white),
          )
        ],
      ),

      body: AbsorbPointer(
        absorbing: isLoading,
        child: Stack(
          children: [
            items.isEmpty
                ? _buildEmptyCart(context)
                : _buildCartList(context, cartData, items),

            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ---------------- EMPTY CART ----------------
  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.cart,
                size: 70, color: AppColors.greyDark),
            const SizedBox(height: 16),
            const Text("Your cart is empty",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white)),
            const SizedBox(height: 6),
            const Text("Add items to get started",
                style: TextStyle(color: AppColors.grey)),

            const SizedBox(height: 20),

            /// 🔥 Browse Category Button (WHITE)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, "/home");
              },
              icon: const Icon(CupertinoIcons.square_grid_2x2,
                  color: Colors.black),
              label: const Text("Browse Categories"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// ---------------- CART LIST ----------------
  Widget _buildCartList(
      BuildContext context, Map<String, dynamic> cartData, List items) {
    final totalAmount = cartData['totalAmount'] ?? 0;
    final totalDiscount = cartData['totalDiscount'] ?? 0;
    final gstCharge = cartData['gstCharge'] ?? 0;
    final serviceCharge = cartData['serviceCharge'] ?? 0;

    return RefreshIndicator(
      onRefresh: _refreshCart,
      color: AppColors.white,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...items.map((item) => _buildCartItem(item)),

                const SizedBox(height: 16),

                /// PRICE DETAILS
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
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.white)),
                      const SizedBox(height: 10),
                      _priceRow("Items Total", totalAmount),
                      _priceRow("Discount", -totalDiscount),
                      _priceRow("GST", gstCharge),
                      _priceRow("Service Charge", serviceCharge),
                      const Divider(color: AppColors.divider),
                      _priceRow("Grand Total",
                          cartData['grand_total'] ?? totalAmount,
                          isBold: true),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// CHECKOUT BAR
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Text(
                  "₹${cartData['grand_total'] ?? totalAmount}",
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/order-summary'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 12),
                  ),
                  child: const Text("Checkout"),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ---------------- CART ITEM ----------------
  Widget _buildCartItem(Map<String, dynamic> item) {
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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(item['image'],
                    width: 70, height: 70, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'],
                        style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text("₹${item['price'] / 100}",
                        style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    /// Quantity Controls
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(CupertinoIcons.minus,
                                size: 16, color: AppColors.white),
                            onPressed: item['quantity'] > 1
                                ? () {
                                    ref
                                        .read(cartProvider.notifier)
                                        .updateCartItem(item['id'],
                                            item['quantity'] - 1);
                                  }
                                : null,
                          ),
                          Text(item['quantity'].toString(),
                              style:
                                  const TextStyle(color: AppColors.white)),
                          IconButton(
                            icon: const Icon(CupertinoIcons.plus,
                                size: 16, color: AppColors.white),
                            onPressed: () {
                              ref
                                  .read(cartProvider.notifier)
                                  .updateCartItem(
                                      item['id'], item['quantity'] + 1);
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _actionButton("Remove", CupertinoIcons.delete, () {
                ref.read(cartProvider.notifier).removeItem(item['id']);
              }),
              _actionButton("Save", CupertinoIcons.heart, () {}),
              _actionButton("Buy Now", CupertinoIcons.bolt, () {}),
            ],
          )
        ],
      ),
    );
  }

  Widget _actionButton(String text, IconData icon, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: AppColors.grey),
      label: Text(text,
          style: const TextStyle(color: AppColors.grey, fontSize: 12)),
    );
  }

  Widget _priceRow(String title, num value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(title,
              style: TextStyle(
                  color: AppColors.grey,
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.normal)),
          const Spacer(),
          Text("₹${value / 100}",
              style: TextStyle(
                  color: isBold ? AppColors.white : AppColors.grey,
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
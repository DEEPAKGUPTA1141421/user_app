import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/cart_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  static const brandColor = Color(0xFFFF5200);

  @override
  void initState() {
    super.initState();
    // Fetch cart data when screen loads
    Future.microtask(() => ref.read(cartProvider.notifier).fetchCart());
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final isLoading = cartState['isLoading'] as bool;
    final cartData = cartState['cartData'] ?? {};
    final items = (cartData['items'] ?? []) as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("My Cart"),
            Text(
              "${items.length} ${items.length == 1 ? "item" : "items"}",
              style: const TextStyle(fontSize: 12, color: Colors.black),
            )
          ],
        ),
        foregroundColor: Colors.black,
        actions: const [Icon(Icons.shopping_bag, color: brandColor)],
      ),

      // Disable interaction when loading
      body: AbsorbPointer(
        absorbing: isLoading,
        child: Stack(
          children: [
            items.isEmpty
                ? _buildEmptyCart()
                : _buildCartList(context, cartData, items),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: brandColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.shopping_bag, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("Your cart is empty",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Add items to get started",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList(
      BuildContext context, Map<String, dynamic> cartData, List items) {
    final totalAmount = cartData['totalAmount'] ?? 0;
    final totalDiscount = cartData['totalDiscount'] ?? 0;
    final gstCharge = cartData['gstCharge'] ?? 0;
    final serviceCharge = cartData['serviceCharge'] ?? 0;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...items.map((item) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Image.network(item['image'],
                              width: 64, height: 64, fit: BoxFit.cover),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                Text("₹${item['price'] / 100}",
                                    style: const TextStyle(
                                        color: brandColor,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: item['quantity'] > 1
                                          ? () {
                                              ref
                                                  .read(cartProvider.notifier)
                                                  .updateCartItem(item['id'],
                                                      item['quantity'] - 1);
                                            }
                                          : null,
                                    ),
                                    Text(item['quantity'].toString()),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        ref
                                            .read(cartProvider.notifier)
                                            .updateCartItem(item['id'],
                                                item['quantity'] + 1);
                                      },
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () {
                                        ref
                                            .read(cartProvider.notifier)
                                            .removeItem(item['id']);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),

              const SizedBox(height: 16),

              // Price details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Price Details",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("Items Total: ₹${totalAmount / 100}"),
                      Text("Discount: -₹${totalDiscount / 100}"),
                      Text("GST: ₹${gstCharge / 100}"),
                      Text("Service Charge: ₹${serviceCharge / 100}"),
                      const Divider(),
                      Text(
                        "Grand Total: ₹${cartData['grand_total'] ?? totalAmount}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: brandColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(
                "Total: ₹${cartData['grand_total'] ?? totalAmount}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: brandColor),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/order-summary'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  "Checkout",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

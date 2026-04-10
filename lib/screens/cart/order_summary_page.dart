import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/cart_provider.dart';
import '../../widgets/address_selector.dart';
import '../../utils/app_colors.dart';
import 'coupon_and_offers_screen.dart';

class OrderSummaryPage extends ConsumerStatefulWidget {
  const OrderSummaryPage({super.key});

  @override
  ConsumerState<OrderSummaryPage> createState() =>
      _OrderSummaryPageState();
}

class _OrderSummaryPageState
    extends ConsumerState<OrderSummaryPage> {
  Map<String, dynamic>? selectedAddress;

  void showAddressModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => DeliveryAddressSelector(
        onAddressSelect: (address) {
          setState(() => selectedAddress = address);
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartData = cartState['cartData'] ?? {};
    final items = (cartData['items'] ?? []) as List;

    final totalAmount =
        (cartData['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final discount =
        (cartData['totalDiscount'] as num?)?.toDouble() ?? 0.0;
    final gst =
        (cartData['gstCharge'] as num?)?.toDouble() ?? 0.0;
    final service =
        (cartData['serviceCharge'] as num?)?.toDouble() ?? 0.0;
    final delivery =
        (cartData['deliveryCharge'] as num?)?.toDouble() ?? 0.0;
    final grandTotal =
        (cartData['grandTotal'] as num?)?.toDouble() ??
            totalAmount;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text("Order Summary",
            style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAddressCard(),

                const SizedBox(height: 12),

                ...items.map((e) =>
                    _buildCartItem(e as Map<String, dynamic>)),

                const SizedBox(height: 12),

                if (discount > 0)
                  _discountBanner(discount),

                const SizedBox(height: 12),

                _priceSection(
                    totalAmount, discount, gst, service, delivery, grandTotal),

                const SizedBox(height: 12),

                CouponAndOffersCard(
                  onApply: () {},
                  onBuy: () {},
                ),
              ],
            ),
          ),

          /// ✅ Checkout Button
          _buildCheckoutButton(cartData, discount.toInt()),
        ],
      ),
    );
  }

  /// ================= ADDRESS =================
  Widget _buildAddressCard() {
    final name = selectedAddress?['name'] ?? 'John Doe';
    final line = selectedAddress?['line1'] ?? '';
    final phone = selectedAddress?['phone'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Delivery Address",
                  style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: showAddressModal,
                child: const Text("Change",
                    style: TextStyle(color: AppColors.grey)),
              )
            ],
          ),
          const SizedBox(height: 6),
          Text(name,
              style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(line,
              style: const TextStyle(color: AppColors.grey)),
          const SizedBox(height: 2),
          Text(phone,
              style: const TextStyle(
                  color: AppColors.white, fontSize: 12)),
        ],
      ),
    );
  }

  /// ================= CART ITEM =================
  Widget _buildCartItem(Map<String, dynamic> item) {
    final price =
        (item['price'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          item['image'] != null &&
                  (item['image'] as String).isNotEmpty
              ? Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image:
                          NetworkImage(item['image'] as String),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.grey),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? '',
                    style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  "₹${price.toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ================= DISCOUNT =================
  Widget _discountBanner(double value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: Colors.greenAccent),
          const SizedBox(width: 8),
          Text("You saved ₹${value.toStringAsFixed(2)}",
              style: const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// ================= PRICE =================
  Widget _priceSection(double total, double discount,
      double gst, double service, double delivery, double grand) {
    return Container(
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
                  color: AppColors.white,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _priceRow("Items Total", total),
          if (discount > 0)
            _priceRow("Discount", -discount,
                isDiscount: true),
          if (gst > 0) _priceRow("GST", gst),
          if (service > 0)
            _priceRow("Service Charge", service),
          if (delivery > 0)
            _priceRow("Delivery", delivery)
          else
            _priceRow("Delivery", 0, isFree: true),
          const Divider(color: AppColors.divider),
          _priceRow("Grand Total", grand,
              isBold: true),
        ],
      ),
    );
  }

  /// ================= CHECKOUT BUTTON =================
  Widget _buildCheckoutButton(
      Map<String, dynamic> cartData, int discountAmount) {
    final total =
        (cartData['grandTotal'] as num?)?.toDouble() ??
            (cartData['totalAmount'] as num?)?.toDouble() ??
            0.0;

    final original =
        (cartData['totalAmount'] as num?)?.toDouble() ??
            0.0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
              top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text("₹${total.toStringAsFixed(2)}",
                    style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                if (discountAmount > 0)
                  Text(
                    "₹${original.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                      decoration:
                          TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                '/payment',
                arguments: {
                  'grandTotal': total,
                },
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text("Continue",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= PRICE ROW =================
  Widget _priceRow(String title, double value,
      {bool isBold = false,
      bool isDiscount = false,
      bool isFree = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(title,
              style: TextStyle(
                  color: isBold
                      ? AppColors.white
                      : AppColors.grey,
                  fontWeight: isBold
                      ? FontWeight.bold
                      : FontWeight.normal)),
          const Spacer(),
          isFree
              ? const Text("FREE",
                  style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold))
              : Text(
                  "${isDiscount ? '-' : ''}₹${value.abs().toStringAsFixed(2)}",
                  style: TextStyle(
                    color: isDiscount
                        ? Colors.greenAccent
                        : isBold
                            ? AppColors.white
                            : AppColors.grey,
                    fontWeight: isBold
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
        ],
      ),
    );
  }
}
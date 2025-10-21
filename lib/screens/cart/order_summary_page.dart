import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/cart_provider.dart';
import '../../provider/rider_provider.dart';
import '../../widgets/address_selector.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'coupon_and_offers_screen.dart';
class OrderSummaryPage extends ConsumerStatefulWidget {
  const OrderSummaryPage({super.key});
  static const brandColor = Color(0xFFFF5200);

  @override
  ConsumerState<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends ConsumerState<OrderSummaryPage> {
  Map<String, dynamic>? selectedAddress;

  void showAddressModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: DeliveryAddressSelector(
            onAddressSelect: (address) {
              // Directly set selectedAddress when user selects
              setState(() {
                selectedAddress = address;
              });
            },
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  void createSound(BuildContext context) async {
    bool? canVibrate = await Vibration.hasVibrator();
    const vibrationDuration = Duration(milliseconds: 2000);

    if (canVibrate ?? false) {
      Vibration.vibrate(
        pattern: [0, 100, 50, 100, 50, 100, 50, 100, 50, 100],
        intensities: [128, 255, 200, 255, 200],
      );
      await Future.delayed(vibrationDuration);
    } else {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (context.mounted) {
      Navigator.pushNamed(context, "/payment");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to riderPod changes to automatically update selectedAddress
    ref.listen<Map<String, dynamic>>(riderPod, (previous, next) {
      final userDetail = next['user_detail'] ?? {};
      final addresses = (userDetail['addresses'] ?? []) as List<dynamic>;

      if (addresses.isNotEmpty) {
        final newDefault = addresses.firstWhere(
          (a) => a['default'] == true,
          orElse: () => addresses.first,
        );

        if (selectedAddress == null ||
            selectedAddress!['id'] != newDefault['id']) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              selectedAddress = newDefault;
            });
          });
        }
      }
    });

    final cartState = ref.watch(cartProvider);
    final cartData = cartState['cartData'] ?? {};
    final items = (cartData['items'] ?? []) as List<dynamic>;
    final discountAmount = cartData['discount_amount'] ?? 0;

    // Fallback if riderPod already has addresses but selectedAddress is null
    final riderState = ref.watch(riderPod);
    final userDetail = riderState['user_detail'] ?? {};
    final addresses = (userDetail['addresses'] ?? []) as List<dynamic>;

    if (addresses.isNotEmpty && selectedAddress == null) {
      selectedAddress = addresses.firstWhere(
        (a) => a['default'] == true,
        orElse: () => addresses.first,
      );
    }

    final userName = selectedAddress?['name'] ?? 'John Doe';
    final kind = selectedAddress?['kind'] ?? 'HOME';
    final line1 = selectedAddress?['line1'] ?? '';
    final pincode = selectedAddress?['pincode'] ?? '';
    final phone = selectedAddress?['phone'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Order Summary"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              // Progress Steps
              _buildProgressSteps(),
              // Delivery Address Card
              _buildDeliveryAddressCard(userName, kind, line1, pincode, phone),

              // Cart Items
              ...items.map((item) => _buildCartItem(item)).toList(),

              // Discount Info
              if (discountAmount > 0) _buildDiscountCard(discountAmount),
              
              // Price Details
              _buildPriceDetails(cartData, discountAmount),
              CouponAndOffersCard(
  onApply: () => print("Apply Coupon Pressed"),
  onBuy: () => print("Buy Prime Pressed"),
),

            ],
          ),

          // Bottom Checkout Button
          _buildCheckoutButton(cartData, discountAmount),
        ],
      ),
    );
  }

  Widget _buildProgressSteps() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: OrderSummaryPage.brandColor,
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text("Address",
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Container(height: 1, color: OrderSummaryPage.brandColor, width: 20),
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: OrderSummaryPage.brandColor,
                  child: const Text(
                    "2",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                const Text("Order Summary",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey, width: 20),
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  child: const Text(
                    "3",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 4),
                const Text("Payment",
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressCard(String userName, String kind, String line1,
      String pincode, String phone) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Deliver to:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              TextButton(
                onPressed: showAddressModal,
                child: const Text("Change",
                    style: TextStyle(color: OrderSummaryPage.brandColor)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(userName, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
                child: Text(kind,
                    style: const TextStyle(fontSize: 10, color: Colors.black)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text("$line1, $pincode",
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(phone,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildCartItem(dynamic item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                    image: NetworkImage(item['image'] ?? ''), fit: BoxFit.cover)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((item['badge'] ?? '').isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(item['badge'] ?? '',
                        style: const TextStyle(fontSize: 10, color: Colors.green)),
                  ),
                Text(item['name'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 2),
                Text(item['subtitle'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text("Qty: ${item['quantity'] ?? 1}"),
                    const SizedBox(width: 8),
                    Text(
                        "Price: ₹${item['price'] ?? item['originalPrice'] ?? 0}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountCard(int discountAmount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200)),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 6),
          Text("You'll save ₹$discountAmount on this order!",
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPriceDetails(Map<String, dynamic> cartData, int discountAmount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Price Details", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Items Total: ₹${cartData['totalAmount'] ?? 0}"),
          Text("Discount: -₹$discountAmount"),
          Text("GST: ₹${cartData['gstCharge'] ?? 0}"),
          Text("Service Charge: ₹${cartData['serviceCharge'] ?? 0}"),
          const Divider(),
          Text(
              "Grand Total: ₹${cartData['grand_total'] ?? cartData['totalAmount'] ?? 0}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: OrderSummaryPage.brandColor)),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(Map<String, dynamic> cartData, int discountAmount) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "₹${cartData['grand_total'] ?? cartData['totalAmount'] ?? 0}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (discountAmount > 0)
                  Text(
                    "₹${cartData['totalAmount'] ?? 0}",
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough),
                  ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => createSound(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: OrderSummaryPage.brandColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "Continue",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/payment/razorpay_gateway.dart';
import '../../provider/cart_provider.dart';
import '../../provider/checkout_provider.dart';
import '../../provider/rider_provider.dart';
import '../../provider/zone_provider.dart';
import '../../provider/interaction_tracker_provider.dart';
import '../../widgets/address_selector.dart';
import '../../widgets/membership_animation.dart';
import '../../widgets/slide_to_pay_button.dart';
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
  bool? _serviceable; // null = not checked, true/false = result
  bool _zoneChecking = false;
  bool _placingOrder = false;
  final _slideKey = GlobalKey<SlideToPayButtonState>();

  late final RazorpayGateway _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = createRazorpayGateway();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final addresses = ref.read(riderPod).addresses;
      final defaultAddr = addresses.cast<Map<String, dynamic>>().firstWhere(
            (a) => a['default'] == true,
            orElse: () => addresses.isNotEmpty
                ? addresses.first as Map<String, dynamic>
                : <String, dynamic>{},
          );
      if (defaultAddr.isNotEmpty) {
        _onAddressSelected(defaultAddr);
      }
    });
  }

  @override
  void dispose() {
    _razorpay.dispose();
    super.dispose();
  }

  Future<void> _toggleMembership({required bool add}) async {
    final notifier = ref.read(cartProvider.notifier);
    if (add) {
      await notifier.addMembership();
    } else {
      await notifier.removeMembership();
    }
    if (!mounted) return;
    final error = ref.read(cartProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    showMembershipAnimation(context, added: add);
  }

  void _onAddressSelected(Map<String, dynamic> address) {
    setState(() {
      selectedAddress = address;
      _serviceable = null;
      _zoneChecking = false;
    });
    ref.read(checkoutProvider.notifier).setAddress(address);
    _checkZone(address);
  }

  Future<void> _checkZone(Map<String, dynamic> address) async {
    final lat = double.tryParse(address['latitude']?.toString() ?? '');
    final lng = double.tryParse(address['longitude']?.toString() ?? '');
    if (lat == null || lng == null) return;
    if (mounted) setState(() => _zoneChecking = true);
    await ref.read(zonePod.notifier).check(lat, lng);
    if (mounted) {
      setState(() {
        _serviceable = ref.read(zonePod).serviceable;
        _zoneChecking = false;
      });
    }
  }

  // ================= CHECKOUT FLOW =================

  Future<void> _startCheckout() async {
    if (selectedAddress == null) {
      _toast('Please select a delivery address');
      _slideKey.currentState?.reset();
      return;
    }
    if (_serviceable == false) {
      _toast('Delivery is not available to this address yet', isError: true);
      _slideKey.currentState?.reset();
      return;
    }

    for (final it in ref.read(cartProvider).items) {
      final pid = ((it as Map)['productId'] ?? it['id']).toString();
      if (pid.isNotEmpty) {
        InteractionBuffer.instance.trackNow(
          productId: pid,
          type: InteractionType.beginCheckout,
          context: InteractionContext.cart,
        );
      }
    }

    await _showPaymentMethodSheet();
    // If no payment method was chosen (sheet dismissed), snap the slider back.
    if (!_placingOrder) {
      _slideKey.currentState?.reset();
    }
  }

  Future<void> _showPaymentMethodSheet() {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PaymentMethodSheet(
        onSelectCod: () {
          Navigator.pop(context);
          _placeOrder(gateway: 'cod');
        },
        onSelectOnline: () {
          Navigator.pop(context);
          _placeOrder(gateway: 'razorpay');
        },
      ),
    );
  }

  Future<void> _placeOrder({required String gateway}) async {
    if (_placingOrder) return;
    setState(() => _placingOrder = true);

    final checkoutNotifier = ref.read(checkoutProvider.notifier);
    final bookingOk = await checkoutNotifier.createBooking(
      deliveryAddress: selectedAddress!['id'] as String,
    );
    if (!mounted) return;
    if (!bookingOk) {
      setState(() => _placingOrder = false);
      _slideKey.currentState?.reset();
      _toast(ref.read(checkoutProvider).error ?? 'Could not create order',
          isError: true);
      return;
    }

    final user = ref.read(riderPod).user;
    final userId = (user['id'] ?? user['userId'] ?? '').toString();

    final paymentOk = await checkoutNotifier.createPayment(
      userId: userId,
      gateway: gateway,
    );
    if (!mounted) return;
    if (!paymentOk) {
      setState(() => _placingOrder = false);
      _slideKey.currentState?.reset();
      _toast(ref.read(checkoutProvider).error ?? 'Payment setup failed',
          isError: true);
      return;
    }

    if (gateway == 'cod') {
      setState(() => _placingOrder = false);
      _trackPurchase(isCod: true);
      _goToOrderSuccess();
      return;
    }

    _openRazorpayCheckout();
  }

  void _openRazorpayCheckout() {
    final state = ref.read(checkoutProvider);
    final orderId = state.razorpayOrderId;
    final keyId = state.razorpayKeyId;

    if (orderId == null || keyId == null) {
      setState(() => _placingOrder = false);
      _slideKey.currentState?.reset();
      _toast('Could not start online payment. Please try again.',
          isError: true);
      return;
    }

    final user = ref.read(riderPod).user;

    try {
      _razorpay.open(
        keyId: keyId,
        orderId: orderId,
        currency: state.razorpayCurrency ?? 'INR',
        amountPaise: state.razorpayAmountPaise,
        name: 'Dashly',
        description: 'Order Payment',
        contact: (user['phone'] ?? '').toString(),
        email: (user['email'] ?? '').toString(),
        onSuccess: (paymentId, respOrderId, signature) =>
            _onRazorpaySuccess(),
        onError: _onRazorpayError,
      );
    } catch (e) {
      setState(() => _placingOrder = false);
      _slideKey.currentState?.reset();
      _toast('Could not open payment gateway: $e', isError: true);
    }
  }

  Future<void> _onRazorpaySuccess() async {
    final verified = await ref.read(checkoutProvider.notifier).validatePayment(
          gateway: 'razorpay',
          merchantOrderId: ref.read(checkoutProvider).transactionId,
        );
    if (!mounted) return;
    setState(() => _placingOrder = false);

    if (verified) {
      _trackPurchase(isCod: false);
      _goToOrderSuccess();
    } else {
      _slideKey.currentState?.reset();
      _toast('Payment received but verification failed. Contact support.',
          isError: true);
    }
  }

  void _onRazorpayError(String message) {
    if (!mounted) return;
    setState(() => _placingOrder = false);
    _slideKey.currentState?.reset();
    _toast(message, isError: true);
  }

  void _goToOrderSuccess() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/order-success',
      (route) => route.isFirst,
    );
  }

  void _trackPurchase({required bool isCod}) {
    final type =
        isCod ? InteractionType.purchaseCod : InteractionType.purchasePrepaid;
    for (final it in ref.read(cartProvider).items) {
      final pid = ((it as Map)['productId'] ?? it['id']).toString();
      if (pid.isNotEmpty) {
        InteractionBuffer.instance.trackNow(
          productId: pid,
          type: type,
          context: InteractionContext.cart,
        );
      }
    }
  }

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? Colors.redAccent : null,
    ));
  }

  void showAddressModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => DeliveryAddressSelector(
        onAddressSelect: (address) {
          Navigator.pop(context);
          _onAddressSelected(address);
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartData = cartState.cartData;
    final items = cartState.items;

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
    final membershipCharge =
        (cartData['membershipCharge'] as num?)?.toDouble() ?? 0.0;
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

                _priceSection(totalAmount, discount, gst, service, delivery,
                    membershipCharge, grandTotal),

                const SizedBox(height: 12),

                CouponAndOffersCard(
                  onApply: () {},
                  onBuy: () => _toggleMembership(add: true),
                  onRemove: () => _toggleMembership(add: false),
                  totalDiscount: discount,
                  deliveryCharge: delivery,
                  membershipOffer:
                      cartData['membershipOffer'] as Map<String, dynamic>?,
                  membershipAdded: cartState.membershipAdded,
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
          if (_zoneChecking) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
          ] else if (_serviceable != null) ...[
            const SizedBox(height: 10),
            _zoneBanner(_serviceable!),
          ],
        ],
      ),
    );
  }

  Widget _zoneBanner(bool serviceable) {
    return Row(
      children: [
        Icon(
          serviceable ? Icons.check_circle_outline : Icons.cancel_outlined,
          size: 14,
          color: serviceable ? Colors.greenAccent : Colors.redAccent,
        ),
        const SizedBox(width: 6),
        Text(
          serviceable
              ? 'Delivery available to this address'
              : 'This area is not yet serviceable',
          style: TextStyle(
            color: serviceable ? Colors.greenAccent : Colors.redAccent,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
      double gst, double service, double delivery, double membership, double grand) {
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
          if (membership > 0)
            _priceRow("Membership", membership),
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
        child: SizedBox(
          width: double.infinity,
          child: SlideToPayButton(
            key: _slideKey,
            enabled: _serviceable != false,
            loading: _placingOrder,
            text: "Pay ₹${total.toStringAsFixed(2)}",
            width: MediaQuery.of(context).size.width - 28,
            onConfirm: _startCheckout,
          ),
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

// ================= PAYMENT METHOD SHEET =================
class _PaymentMethodSheet extends StatelessWidget {
  final VoidCallback onSelectCod;
  final VoidCallback onSelectOnline;

  const _PaymentMethodSheet({
    required this.onSelectCod,
    required this.onSelectOnline,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              "Choose Payment Method",
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _MethodTile(
              icon: Icons.account_balance_wallet_outlined,
              title: "Pay Online",
              subtitle: "UPI, Cards, Netbanking via Razorpay",
              onTap: onSelectOnline,
            ),
            const SizedBox(height: 10),
            _MethodTile(
              icon: Icons.payments_outlined,
              title: "Cash on Delivery",
              subtitle: "Pay when your order arrives",
              onTap: onSelectCod,
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.white, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey),
          ],
        ),
      ),
    );
  }
}
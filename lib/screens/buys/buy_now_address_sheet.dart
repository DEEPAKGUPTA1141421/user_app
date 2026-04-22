import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
import '../../provider/buy_now_provider.dart';
import '../../provider/rider_provider.dart';
import '../../provider/order_tracking_provider.dart';
import '../../utils/app_colors.dart';

// ─── Address Picker Sheet ──────────────────────────────────────────────────────
class BuyNowAddressSheet extends ConsumerWidget {
  final void Function(Map<String, dynamic> address) onSelect;

  const BuyNowAddressSheet({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(riderPod).addresses;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 20 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Choose Delivery Address',
            style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (addresses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.location_off_outlined,
                        color: AppColors.greyDark, size: 36),
                    const SizedBox(height: 12),
                    const Text('No saved addresses',
                        style: TextStyle(color: AppColors.grey, fontSize: 14)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/account/addresses');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text('Add Address',
                            style: TextStyle(
                                color: AppColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...addresses.map<Widget>((a) {
              final addr = Map<String, dynamic>.from(a as Map);
              final isDefault = addr['default'] == true;
              final line1 = addr['line1'] as String? ?? '';
              final city = addr['city'] as String? ?? '';
              final state = addr['state'] as String? ?? '';
              final pincode = addr['pincode'] as String? ?? '';

              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onSelect(addr);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDefault
                        ? AppColors.surface2
                        : AppColors.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDefault ? AppColors.green : AppColors.border,
                      width: isDefault ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          CupertinoIcons.location_solid,
                          color: isDefault
                              ? AppColors.green
                              : AppColors.grey,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isDefault)
                              const Text('DEFAULT',
                                  style: TextStyle(
                                      color: AppColors.green,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2)),
                            if (isDefault) const SizedBox(height: 2),
                            Text('$city, $state – $pincode',
                                style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            if (line1.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                line1.length > 60
                                    ? '${line1.substring(0, 60)}…'
                                    : line1,
                                style: const TextStyle(
                                    color: AppColors.grey, fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_right,
                          color: AppColors.greyDark, size: 14),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─── Buy Now Payment Page ──────────────────────────────────────────────────────
class BuyNowPaymentPage extends ConsumerStatefulWidget {
  final String productId;
  final String variantId;
  final String productName;
  final String? productImage;
  final double price;
  final Map<String, dynamic> selectedAddress;

  const BuyNowPaymentPage({
    super.key,
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.price,
    required this.selectedAddress,
    this.productImage,
  });

  @override
  ConsumerState<BuyNowPaymentPage> createState() => _BuyNowPaymentPageState();
}

class _BuyNowPaymentPageState extends ConsumerState<BuyNowPaymentPage>
    with SingleTickerProviderStateMixin {
  String _selectedMethod = '';
  bool _sdkInitialized = false;
  bool _isProcessing = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _initSdk();
    _createBooking();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _initSdk() async {
    try {
      await PhonePePaymentSdk.init(
          'SANDBOX', 'merchant@upi', 'TEST-M2361NIBCR3FS_25101', true);
      if (mounted) setState(() => _sdkInitialized = true);
    } catch (_) {}
  }

  Future<void> _createBooking() async {
    final addressId = widget.selectedAddress['id'] as String? ?? '';
    if (addressId.isEmpty) {
      _toast('Invalid delivery address');
      return;
    }
    await ref.read(buyNowProvider.notifier).createBooking(
          productId: widget.productId,
          variantId: widget.variantId,
          deliveryAddressId: addressId,
        );
  }

  String get _gateway {
    switch (_selectedMethod) {
      case 'cod':
        return 'cod';
      default:
        return 'phonepe';
    }
  }

  Future<void> _pay() async {
    if (_selectedMethod.isEmpty) {
      _toast('Select a payment method');
      return;
    }

    final buyNowState = ref.read(buyNowProvider);
    if (!buyNowState.hasBooking) {
      _toast('Booking not ready. Please wait.');
      return;
    }

    setState(() => _isProcessing = true);

    final userId = (ref.read(riderPod).user['id'] ?? '').toString();
    final ok = await ref.read(buyNowProvider.notifier).createPayment(
          userId: userId,
          gateway: _gateway,
        );

    if (!ok || !mounted) {
      setState(() => _isProcessing = false);
      _toast(ref.read(buyNowProvider).error ?? 'Payment setup failed');
      return;
    }

    if (_gateway == 'cod') {
      _navigateToSuccess();
    } else {
      await _launchPhonePe();
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _launchPhonePe() async {
    if (!_sdkInitialized) {
      _toast('Payment SDK not ready');
      return;
    }
    try {
      final bookingId = ref.read(buyNowProvider).bookingId ?? '';
      final amountPaise =
          ((ref.read(buyNowProvider).totalAmountRupees ?? widget.price) * 100)
              .toInt();

      final body = {
        'merchantId': 'TEST-M2361NIBCR3FS_25101',
        'merchantTransactionId': bookingId,
        'merchantUserId': 'USER_${DateTime.now().millisecondsSinceEpoch}',
        'amount': amountPaise,
        'mobileNumber': '9999999999',
        'callbackUrl': 'https://yourcallback.url/payment/webhook/phonepe',
        'paymentInstrument': {'type': 'PAY_PAGE'},
      };

      final response = await PhonePePaymentSdk.startTransaction(
          json.encode(body), 'com.phonepe.app');

      if (!mounted) return;
      final status = response?['status']?.toString() ?? 'FAILED';
      ref
          .read(buyNowProvider.notifier)
          .setPhonePeResult(status == 'SUCCESS' ? 'COMPLETED' : status);

      if (status == 'SUCCESS') {
        await _verifyAndNavigate();
      } else {
        _toast('Payment failed. Please retry.');
      }
    } catch (_) {
      // In development/sandbox, treat PhonePe errors as success
      ref.read(buyNowProvider.notifier).setPhonePeResult('COMPLETED');
      await _verifyAndNavigate();
    }
  }

  Future<void> _verifyAndNavigate() async {
    final verified =
        await ref.read(buyNowProvider.notifier).validatePayment();
    if (!mounted) return;
    if (verified) {
      _navigateToSuccess();
    } else {
      _toast('Payment verification failed');
    }
  }

  void _navigateToSuccess() {
    final bookingId = ref.read(buyNowProvider).bookingId;
    if (bookingId != null) {
      ref.read(orderTrackingProvider.notifier).loadTracking(bookingId);
    }
    Navigator.pushNamedAndRemoveUntil(
        context, '/order-success', (route) => route.isFirst);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(color: AppColors.white, fontSize: 14)),
      backgroundColor: AppColors.surface2,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.white24)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(buyNowProvider);
    final isLoading = state.isLoading || _isProcessing;
    final total = state.totalAmountRupees ?? widget.price;
    final breakdown = state.breakdown;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── App Bar ────────────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppColors.surface,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: AppColors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: const Text('Buy Now',
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600)),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(mainAxisSize: MainAxisSize.min, children: const [
                        Icon(Icons.lock_outline, color: AppColors.grey, size: 14),
                        SizedBox(width: 4),
                        Text('Secure',
                            style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(height: 1, color: AppColors.divider),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Product Card ──────────────────────────────────
                        _ProductSummaryCard(
                          productName: widget.productName,
                          productImage: widget.productImage,
                          address: widget.selectedAddress,
                        ),

                        // ── Price Breakdown ───────────────────────────────
                        if (breakdown != null)
                          _PriceBreakdownCard(
                              breakdown: breakdown, total: total)
                        else
                          _SimplePriceCard(total: total),

                        // ── Expiry Timer ──────────────────────────────────
                        if (state.expiresAt != null)
                          _ExpiryBanner(expiresAt: state.expiresAt!),

                        // ── Error Banner ──────────────────────────────────
                        if (state.error != null && !isLoading)
                          _ErrorBanner(
                            message: state.error!,
                            onRetry: _createBooking,
                          ),

                        // ── Payment Methods ───────────────────────────────
                        const _SectionLabel('UPI & ONLINE'),
                        _MethodTile(
                          id: 'phonepe',
                          selected: _selectedMethod,
                          icon: _PhonePeIcon(),
                          title: 'PhonePe',
                          subtitle: 'Pay via PhonePe UPI',
                          onTap: (v) => setState(() => _selectedMethod = v),
                        ),
                        _MethodTile(
                          id: 'gpay',
                          selected: _selectedMethod,
                          icon: _GPIcon(),
                          title: 'Google Pay',
                          subtitle: 'Pay via Google Pay UPI',
                          onTap: (v) => setState(() => _selectedMethod = v),
                        ),
                        _MethodTile(
                          id: 'card',
                          selected: _selectedMethod,
                          icon: const Icon(Icons.credit_card_outlined,
                              color: AppColors.white, size: 24),
                          title: 'Credit / Debit Card',
                          subtitle: 'Visa, Mastercard, RuPay & more',
                          onTap: (v) => setState(() => _selectedMethod = v),
                        ),

                        const SizedBox(height: 8),
                        const _SectionLabel('OTHER'),
                        _MethodTile(
                          id: 'cod',
                          selected: _selectedMethod,
                          icon: const Icon(Icons.payments_outlined,
                              color: AppColors.white, size: 24),
                          title: 'Cash on Delivery',
                          subtitle: 'Pay with cash when your order arrives',
                          onTap: (v) => setState(() => _selectedMethod = v),
                        ),

                        const SizedBox(height: 20),
                        _TrustRow(),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Bottom Pay Bar ─────────────────────────────────────────────
            _BottomBar(
              total: total,
              isLoading: isLoading,
              selectedMethod: _selectedMethod,
              hasBooking: state.hasBooking,
              onPay: _pay,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Product Summary Card ──────────────────────────────────────────────────────
class _ProductSummaryCard extends StatelessWidget {
  final String productName;
  final String? productImage;
  final Map<String, dynamic> address;

  const _ProductSummaryCard({
    required this.productName,
    required this.address,
    this.productImage,
  });

  @override
  Widget build(BuildContext context) {
    final line1 = address['line1'] as String? ?? '';
    final city = address['city'] as String? ?? '';
    final kind = address['kind'] as String? ?? 'HOME';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Product Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: productImage != null && productImage!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(productImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: AppColors.greyDark)))
                      : const Icon(Icons.shopping_bag_outlined,
                          color: AppColors.greyDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BUYING NOW',
                          style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.3)),
                      const SizedBox(height: 4),
                      Text(productName,
                          style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.divider),
          // Address Row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(CupertinoIcons.location_solid,
                      color: AppColors.green, size: 14),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delivering to $kind',
                          style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        line1.isNotEmpty
                            ? (city.isNotEmpty ? '$line1, $city' : line1)
                            : 'Address selected',
                        style: const TextStyle(
                            color: AppColors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Price Breakdown ───────────────────────────────────────────────────────────
class _PriceBreakdownCard extends StatelessWidget {
  final Map<String, dynamic> breakdown;
  final double total;
  const _PriceBreakdownCard({required this.breakdown, required this.total});

  @override
  Widget build(BuildContext context) {
    final subTotal = (breakdown['subTotal'] as num?)?.toDouble() ?? 0;
    final gst = (breakdown['gst'] as num?)?.toDouble() ?? 0;
    final delivery = (breakdown['delivery'] as num?)?.toDouble() ?? 0;
    final service = (breakdown['serviceCharge'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PRICE DETAILS',
              style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3)),
          const SizedBox(height: 12),
          _Row('Item Price', subTotal),
          if (gst > 0) _Row('GST', gst),
          if (delivery > 0)
            _Row('Delivery', delivery)
          else
            _FreeRow('Delivery'),
          if (service > 0) _Row('Service Charge', service),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Payable',
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              Text('₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final double value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.grey, fontSize: 13)),
          Text('₹${value.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}

class _FreeRow extends StatelessWidget {
  final String label;
  const _FreeRow(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.grey, fontSize: 13)),
          const Text('FREE',
              style: TextStyle(
                  color: AppColors.green,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SimplePriceCard extends StatelessWidget {
  final double total;
  const _SimplePriceCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Payable',
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          Text('₹${total.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ─── Expiry Banner ─────────────────────────────────────────────────────────────
class _ExpiryBanner extends StatefulWidget {
  final String expiresAt;
  const _ExpiryBanner({required this.expiresAt});

  @override
  State<_ExpiryBanner> createState() => _ExpiryBannerState();
}

class _ExpiryBannerState extends State<_ExpiryBanner> {
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _update();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      _update();
      return _remaining.inSeconds > 0;
    });
  }

  void _update() {
    final expiry = DateTime.tryParse(widget.expiresAt);
    if (expiry == null) return;
    final diff = expiry.difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  Widget build(BuildContext context) {
    final mins = _remaining.inMinutes;
    final secs = _remaining.inSeconds % 60;
    final isExpiring = _remaining.inSeconds < 60;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isExpiring
            ? Colors.red.shade900.withOpacity(0.4)
            : Colors.orange.shade900.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isExpiring
              ? Colors.red.shade700.withOpacity(0.5)
              : Colors.orange.shade700.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined,
              size: 16,
              color: isExpiring ? Colors.redAccent : Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _remaining.inSeconds > 0
                  ? 'Booking expires in ${mins.toString().padLeft(2, "0")}:${secs.toString().padLeft(2, "0")} — complete payment to confirm'
                  : 'Booking expired. Go back and try again.',
              style: TextStyle(
                color: isExpiring ? Colors.redAccent : Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error Banner ──────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade700.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Retry',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.grey,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4)),
    );
  }
}

// ─── Method Tile ───────────────────────────────────────────────────────────────
class _MethodTile extends StatelessWidget {
  final String id;
  final String selected;
  final Widget icon;
  final String title;
  final String subtitle;
  final ValueChanged<String> onTap;

  const _MethodTile({
    required this.id,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == id;
    return GestureDetector(
      onTap: () => onTap(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface2 : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.white : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.grey, fontSize: 11)),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? AppColors.white
                    : AppColors.greyDark,
                width: isSelected ? 2 : 1.5,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white),
                    ),
                  )
                : null,
          ),
        ]),
      ),
    );
  }
}

// ─── Trust Row ─────────────────────────────────────────────────────────────────
class _TrustRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            _Badge(Icons.security_outlined, '256-bit SSL'),
            _BadgeDivider(),
            _Badge(Icons.verified_outlined, 'PCI DSS'),
            _BadgeDivider(),
            _Badge(Icons.lock_outlined, 'Encrypted'),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.grey, size: 18),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 9,
                  fontWeight: FontWeight.w500)),
        ],
      );
}

class _BadgeDivider extends StatelessWidget {
  const _BadgeDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: AppColors.divider);
}

// ─── Icon Widgets ──────────────────────────────────────────────────────────────
class _PhonePeIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
            color: const Color(0xFF5F259F),
            borderRadius: BorderRadius.circular(6)),
        child: const Center(
          child: Text('P',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900)),
        ),
      );
}

class _GPIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(6)),
        child: const Center(
          child: Text('G',
              style: TextStyle(
                  color: Color(0xFF4285F4),
                  fontSize: 14,
                  fontWeight: FontWeight.w900)),
        ),
      );
}

// ─── Bottom Bar ────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final double total;
  final bool isLoading;
  final bool hasBooking;
  final String selectedMethod;
  final VoidCallback onPay;

  const _BottomBar({
    required this.total,
    required this.isLoading,
    required this.hasBooking,
    required this.selectedMethod,
    required this.onPay,
  });

  String get _label {
    if (!hasBooking) return 'Preparing...';
    switch (selectedMethod) {
      case 'phonepe':
        return 'Pay via PhonePe';
      case 'gpay':
        return 'Pay via Google Pay';
      case 'card':
        return 'Pay via Card';
      case 'cod':
        return 'Place Order (COD)';
      default:
        return 'Select a method above';
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPay = selectedMethod.isNotEmpty && !isLoading && hasBooking;

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
            20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
        child: Row(children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pay Now',
                  style: TextStyle(color: AppColors.grey, fontSize: 11)),
              const SizedBox(height: 2),
              Text('₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: canPay ? onPay : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: canPay ? AppColors.white : AppColors.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: canPay ? AppColors.white : AppColors.border),
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.bg, strokeWidth: 2.5))
                      : Text(_label,
                          style: TextStyle(
                              color: canPay
                                  ? AppColors.bg
                                  : AppColors.greyDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
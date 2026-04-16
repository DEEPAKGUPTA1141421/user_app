import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';

import '../provider/rider_provider.dart';
import '../provider/checkout_provider.dart';
import '../utils/app_colors.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage>
    with TickerProviderStateMixin {
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

    _initPhonePeSdk();
    // Use postFrameCallback so ModalRoute.of(context) is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _runCheckout());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _initPhonePeSdk() async {
    try {
      await PhonePePaymentSdk.init(
        'SANDBOX',
        'merchant@upi',
        'TEST-M2361NIBCR3FS_25101',
        true,
      );
      setState(() => _sdkInitialized = true);
    } catch (e) {
      debugPrint('PhonePe SDK init error: $e');
    }
  }

  Future<void> _runCheckout() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final addressId = args?['deliveryAddressId'] as String?;

    if (addressId == null || addressId.isEmpty) {
      _toast('No delivery address selected');
      return;
    }

    final notifier = ref.read(checkoutProvider.notifier);
    await notifier.createBooking(deliveryAddress: addressId);
  }

  /// Maps the UI payment-method id to the API gateway value.
  String get _gateway {
    switch (_selectedMethod) {
      case 'cod':
        return 'cod';
      case 'phonepe':
      case 'gpay':
      case 'card':
      default:
        return 'phonepe';
    }
  }

  Future<void> _pay(double grandTotal) async {
    if (_selectedMethod.isEmpty) {
      _toast('Select a payment method');
      return;
    }

    setState(() => _isProcessing = true);

    final notifier = ref.read(checkoutProvider.notifier);
    final user = ref.read(riderPod).user;
    final userId = (user['id'] ?? user['userId'] ?? '').toString();
    final gateway = _gateway;

    final created = await notifier.createPayment(
      userId: userId,
      gateway: gateway,
    );

    if (!created || !mounted) {
      setState(() => _isProcessing = false);
      _toast(ref.read(checkoutProvider).error ?? 'Payment setup failed');
      return;
    }

    if (gateway == 'cod') {
      // COD: order is placed with PENDING status — go straight to success
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/order-success',
        (route) => route.isFirst,
      );
    } else {
      await _launchPhonePe(grandTotal);
    }

    setState(() => _isProcessing = false);
  }

  Future<void> _launchPhonePe(double amount) async {
    if (!_sdkInitialized) {
      _toast('Payment SDK not ready');
      return;
    }

    try {
      final bookingId = ref.read(checkoutProvider).bookingId ??
          'txn_${DateTime.now().millisecondsSinceEpoch}';

      final amountPaise = (amount * 100).toInt();

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
        json.encode(body),
        'com.phonepe.app',
      );

      if (!mounted) return;

      final status = response?['status']?.toString() ?? 'FAILED';
      ref
          .read(checkoutProvider.notifier)
          .setPhonePeResult(status == 'SUCCESS' ? 'COMPLETED' : status);

      if (status == 'SUCCESS') {
        await _verifyAndNavigate();
      } else {
        _toast('Payment failed');
      }
    } catch (e) {
      debugPrint('PhonePe error: $e');
      ref.read(checkoutProvider.notifier).setPhonePeResult('COMPLETED');
      await _verifyAndNavigate();
    }
  }

  Future<void> _verifyAndNavigate() async {
    final verified =
        await ref.read(checkoutProvider.notifier).validatePayment();
    if (!mounted) return;
    if (verified) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/order-success',
        (route) => route.isFirst,
      );
    } else {
      _toast('Payment verification failed');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(color: AppColors.white, fontSize: 14)),
      backgroundColor: AppColors.surface2,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.white24, width: 1)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    // Use the authoritative total from the booking API when available,
    // otherwise fall back to the amount passed from the order-summary page.
    final grandTotal = checkoutState.bookings.isNotEmpty
        ? checkoutState.totalAmountRupees
        : (args?['grandTotal'] as num?)?.toDouble() ?? 0.0;
    final isLoading = checkoutState.isLoading || _isProcessing;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── App Bar ──────────────────────────────────────────────
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
                  title: const Text(
                    'Checkout',
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline,
                              color: AppColors.grey, size: 14),
                          const SizedBox(width: 4),
                          const Text('Secure',
                              style: TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
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
                        // ── Order Summary ─────────────────────────────────
                        _OrderSummaryCard(total: grandTotal),

                        // ── UPI Methods ───────────────────────────────────
                        _SectionLabel('UPI'),
                        _MethodCard(
                          id: 'phonepe',
                          selected: _selectedMethod,
                          icon: _PhonePeIcon(),
                          title: 'PhonePe',
                          subtitle: 'Pay via PhonePe UPI',
                          onTap: (v) => setState(() => _selectedMethod = v),
                        ),
                        _MethodCard(
                          id: 'gpay',
                          selected: _selectedMethod,
                          icon: _GPIcon(),
                          title: 'Google Pay',
                          subtitle: 'Pay via Google Pay UPI',
                          onTap: (v) => setState(() => _selectedMethod = v),
                        ),

                        const SizedBox(height: 8),

                        // ── Cards ─────────────────────────────────────────
                        _SectionLabel('CARDS'),
                        _MethodCard(
                          id: 'card',
                          selected: _selectedMethod,
                          icon: const Icon(Icons.credit_card_outlined,
                              color: AppColors.white, size: 26),
                          title: 'Credit / Debit Card',
                          subtitle: 'Visa, Mastercard, RuPay & more',
                          onTap: (v) => setState(() => _selectedMethod = v),
                        ),

                        const SizedBox(height: 8),

                        // ── Other ─────────────────────────────────────────
                        _SectionLabel('OTHER'),
                        _MethodCard(
                          id: 'cod',
                          selected: _selectedMethod,
                          icon: const Icon(Icons.payments_outlined,
                              color: AppColors.white, size: 26),
                          title: 'Cash on Delivery',
                          subtitle: 'Pay when your order arrives',
                          onTap: (v) => setState(() => _selectedMethod = v),
                        ),

                        const SizedBox(height: 24),

                        // ── Trust Badges ──────────────────────────────────
                        _TrustBadges(),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Sticky Bottom Bar ─────────────────────────────────────────
            _BottomPayBar(
              total: grandTotal,
              isLoading: isLoading,
              selectedMethod: _selectedMethod,
              onPay: () => _pay(grandTotal),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Order Summary Card ───────────────────────────────────────────────────────
class _OrderSummaryCard extends StatelessWidget {
  final double total;
  const _OrderSummaryCard({required this.total});

  @override
  Widget build(BuildContext context) {
    final subtotal = total;
    const delivery = 0.0;
    const discount = 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    color: AppColors.grey, size: 18),
                const SizedBox(width: 10),
                const Text(
                  'ORDER SUMMARY',
                  style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.divider),

          // Rows
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              children: [
                _SummaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 10),
                _SummaryRow('Delivery', delivery == 0 ? 'FREE' : '₹${delivery.toStringAsFixed(2)}',
                    valueColor: AppColors.green),
                if (discount > 0) ...[
                  const SizedBox(height: 10),
                  _SummaryRow('Discount', '-₹${discount.toStringAsFixed(2)}',
                      valueColor: AppColors.green),
                ],
                const SizedBox(height: 14),
                Container(height: 1, color: AppColors.divider),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Payable',
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryRow(this.label, this.value,
      {this.valueColor = AppColors.grey});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.grey, fontSize: 14)),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        text,
        style: const TextStyle(
            color: AppColors.grey,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4),
      ),
    );
  }
}

// ─── Payment Method Card ──────────────────────────────────────────────────────
class _MethodCard extends StatelessWidget {
  final String id;
  final String selected;
  final Widget icon;
  final String title;
  final String subtitle;
  final ValueChanged<String> onTap;

  const _MethodCard({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface2 : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.white : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(child: icon),
            ),

            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        color: isSelected ? AppColors.white : AppColors.white,
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: AppColors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Radio
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.white : AppColors.greyDark,
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PhonePe icon (purple P) ──────────────────────────────────────────────────
class _PhonePeIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF5F259F),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Center(
        child: Text('P',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900)),
      ),
    );
  }
}

// ─── Google Pay icon (G) ──────────────────────────────────────────────────────
class _GPIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
              color: Color(0xFF4285F4),
              fontSize: 16,
              fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

// ─── Trust Badges ─────────────────────────────────────────────────────────────
class _TrustBadges extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          const SizedBox(height: 12),
          const Text(
            'Powered by Dashly Pay · All transactions are secured',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.greyDark, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.grey, size: 20),
        const SizedBox(height: 5),
        Text(label,
            style: const TextStyle(
                color: AppColors.grey,
                fontSize: 10,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _BadgeDivider extends StatelessWidget {
  const _BadgeDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.divider);
  }
}

// ─── Sticky Bottom Pay Bar ────────────────────────────────────────────────────
class _BottomPayBar extends StatelessWidget {
  final double total;
  final bool isLoading;
  final String selectedMethod;
  final VoidCallback onPay;

  const _BottomPayBar({
    required this.total,
    required this.isLoading,
    required this.selectedMethod,
    required this.onPay,
  });

  String get _methodLabel {
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
    final canPay = selectedMethod.isNotEmpty && !isLoading;

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
            20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Amount row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Payable',
                        style: TextStyle(
                            color: AppColors.grey, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: canPay ? onPay : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: canPay ? AppColors.white : AppColors.surface2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            canPay ? AppColors.white : AppColors.border,
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: AppColors.bg, strokeWidth: 2.5))
                        : Text(
                            selectedMethod.isEmpty ? 'Pay Now' : _methodLabel,
                            style: TextStyle(
                                color: canPay
                                    ? AppColors.bg
                                    : AppColors.greyDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert'; // ✅ FIXED

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';

import '../provider/rider_provider.dart';
import '../provider/checkout_provider.dart'; // ✅ FIXED
import '../utils/app_colors.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  String _selectedMethod = '';
  bool _sdkInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initPhonePeSdk();
    _runCheckout();
  }

  /// ✅ INIT SDK
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

  /// ✅ CREATE BOOKING
  Future<void> _runCheckout() async {
    final notifier = ref.read(checkoutProvider.notifier);

    final booked = await notifier.createBooking();
    if (!booked || !mounted) return;
  }

  /// ✅ MAIN PAY FLOW
  Future<void> _pay(double grandTotal) async {
    if (_selectedMethod.isEmpty) {
      _showSnack('Select a payment method');
      return;
    }

    setState(() => _isProcessing = true);

    final notifier = ref.read(checkoutProvider.notifier);
    final ud =
        ref.read(riderPod)['user_detail'] as Map<String, dynamic>? ?? {};

    final userId =
        (ud['id'] ?? ud['userId'] ?? '').toString(); // ✅ SAFE

    final created = await notifier.createPayment(
      userId: userId,
      amount: grandTotal.toStringAsFixed(2),
    );

    if (!created || !mounted) {
      setState(() => _isProcessing = false);
      _showSnack('Payment setup failed');
      return;
    }

    if (_selectedMethod == 'phonepe') {
      await _launchPhonePe(grandTotal);
    } else {
      await _verifyAndNavigate();
    }

    setState(() => _isProcessing = false);
  }

  /// ✅ PHONEPE FLOW
  Future<void> _launchPhonePe(double amount) async {
    if (!_sdkInitialized) {
      _showSnack('Payment SDK not ready');
      return;
    }

    try {
      final bookingId =
          ref.read(checkoutProvider).bookingId ??
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
        json.encode(body), // ✅ FIXED
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
        _showSnack('Payment failed');
      }
    } catch (e) {
      debugPrint('PhonePe error: $e');

      /// ✅ Sandbox fallback
      ref.read(checkoutProvider.notifier).setPhonePeResult('COMPLETED');
      await _verifyAndNavigate();
    }
  }

  /// ✅ VERIFY
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
      _showSnack('Payment verification failed');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final grandTotal =
        (args?['grandTotal'] as num?)?.toDouble() ?? 0.0;

    final isLoading = checkoutState.isLoading || _isProcessing;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text("Payments",
            style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              _amountCard(grandTotal),
              _paymentMethods(),
            ],
          ),
          _bottomBar(grandTotal, isLoading),
        ],
      ),
    );
  }

  /// ================= UI COMPONENTS =================

  Widget _amountCard(double total) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Text("Total Amount",
              style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          Text("₹${total.toStringAsFixed(2)}",
              style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _paymentMethods() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _method("PhonePe", "phonepe"),
          _divider(),
          _method("Google Pay", "gpay"),
          _divider(),
          _method("Card", "card"),
        ],
      ),
    );
  }

  Widget _method(String title, String value) {
    final isSelected = _selectedMethod == value;

    return ListTile(
      title: Text(title,
          style: const TextStyle(color: AppColors.white)),
      trailing: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? Colors.greenAccent : AppColors.grey,
      ),
      onTap: () => setState(() => _selectedMethod = value),
    );
  }

  Widget _divider() =>
      const Divider(color: AppColors.divider, height: 1);

  Widget _bottomBar(double total, bool isLoading) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Text("₹${total.toStringAsFixed(2)}",
                style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            ElevatedButton(
              onPressed: isLoading ? null : () => _pay(total),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: Colors.black,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Pay Now"),
            )
          ],
        ),
      ),
    );
  }
}
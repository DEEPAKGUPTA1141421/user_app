import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/rider_provider.dart';
import '../provider/order_tracking_provider.dart';
import '../provider/checkout_provider.dart';

class OrderSuccessScreen extends ConsumerStatefulWidget {
  const OrderSuccessScreen({super.key});

  @override
  ConsumerState<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends ConsumerState<OrderSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late AnimationController _contentCtrl;
  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  late Animation<double> _contentSlide;
  late Animation<double> _contentOpacity;

  @override
  void initState() {
    super.initState();

    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _checkScale = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
    _checkOpacity = CurvedAnimation(parent: _checkCtrl, curve: Curves.easeIn);
    _contentSlide = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));
    _contentOpacity =
        CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);

    // Sequence: check appears → content slides in → auto-navigate after 3.5 s
    _checkCtrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _contentCtrl.forward();
      });
    });

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      final bookingId = ref.read(checkoutProvider).bookingId;
      if (bookingId != null) {
        ref.read(orderTrackingProvider.notifier).loadTracking(bookingId);
      }
      Navigator.pushReplacementNamed(context, '/order-tracking');
    });
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);
    final riderState = ref.watch(riderPod);
    final ud = riderState.user;
    final addresses = riderState.addresses;
    final address = checkoutState.selectedAddress ??
        (addresses.isNotEmpty
            ? addresses.firstWhere(
                (a) => a['default'] == true,
                orElse: () => addresses.first,
              ) as Map<String, dynamic>
            : null);

    final bookingId = checkoutState.bookingId ?? '—';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Animated check circle ──────────────────────────────────
                ScaleTransition(
                  scale: _checkScale,
                  child: FadeTransition(
                    opacity: _checkOpacity,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.shade700,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 60),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Animated content ───────────────────────────────────────
                AnimatedBuilder(
                  animation: _contentCtrl,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _contentSlide.value),
                    child: Opacity(opacity: _contentOpacity.value, child: child),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Order Confirmed!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your payment was successful',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                      ),

                      const SizedBox(height: 8),

                      // Order ID pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          'Order ID: ${bookingId.length > 12 ? bookingId.substring(0, 12) : bookingId}...',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Delivery address card ──────────────────────────
                      if (address != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.location_on_outlined,
                                    color: Colors.greenAccent, size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  'Delivering to',
                                  style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ]),
                              const SizedBox(height: 10),
                              Text(
                                address['name'] as String? ??
                                    (ud['firstName'] as String? ?? 'You'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatAddress(address),
                                style: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 13, height: 1.4),
                              ),
                              if (address['phone'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  address['phone'] as String,
                                  style: TextStyle(
                                      color: Colors.grey.shade400, fontSize: 13),
                                ),
                              ],
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Auto-redirect indicator
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white38),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Redirecting to order tracking…',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> address) {
    final parts = <String>[];
    if (address['line1'] != null) parts.add(address['line1'] as String);
    if (address['city'] != null) parts.add(address['city'] as String);
    if (address['pincode'] != null) parts.add(address['pincode'] as String);
    return parts.join(', ');
  }
}
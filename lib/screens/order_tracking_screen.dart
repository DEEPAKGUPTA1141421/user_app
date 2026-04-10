import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/order_tracking_provider.dart';
import '../provider/checkout_provider.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimCtrl;

  @override
  void initState() {
    super.initState();
    _shimCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();

    // Ensure tracking is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookingId = ref.read(checkoutProvider).bookingId;
      if (bookingId != null &&
          ref.read(orderTrackingProvider).bookingId == null) {
        ref.read(orderTrackingProvider.notifier).loadTracking(bookingId);
      }
    });
  }

  @override
  void dispose() {
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderTrackingProvider);
    final bookingId = ref.watch(checkoutProvider).bookingId ?? state.bookingId ?? '—';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Track Order',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: state.bookingId != null
                ? () => ref
                    .read(orderTrackingProvider.notifier)
                    .loadTracking(state.bookingId!)
                : null,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF222222)),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Order ID card ──────────────────────────────────────
                  _orderIdCard(bookingId, state),

                  const SizedBox(height: 24),

                  // ── Timeline ───────────────────────────────────────────
                  _sectionLabel('ORDER STATUS'),
                  const SizedBox(height: 14),
                  ...List.generate(state.steps.length, (i) {
                    final step = state.steps[i];
                    final isLast = i == state.steps.length - 1;
                    return _timelineItem(step, isLast);
                  }),

                  const SizedBox(height: 28),

                  // ── Payment details ────────────────────────────────────
                  if (state.paymentStatus != null) ...[
                    _sectionLabel('PAYMENT'),
                    const SizedBox(height: 14),
                    _infoCard([
                      _infoRow('Status', _paymentLabel(state.paymentStatus!),
                          valueColor: state.paymentStatus == 'SUCCESS'
                              ? Colors.greenAccent
                              : Colors.orange),
                      _infoRow('Method', 'PhonePe / UPI'),
                    ]),
                    const SizedBox(height: 28),
                  ],

                  // ── Action buttons ─────────────────────────────────────
                  _actionButtons(context),
                ],
              ),
            ),
    );
  }

  Widget _orderIdCard(String bookingId, OrderTrackingState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _statusBadge(state.status),
          const Spacer(),
          Text(
            _formatTimestamp(DateTime.now()),
            style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
          ),
        ]),
        const SizedBox(height: 12),
        const Text('Order ID',
            style: TextStyle(color: Color(0xFF666666), fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          bookingId,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
        ),
      ]),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        bg = Colors.green.shade900;
        fg = Colors.greenAccent;
        label = '✓ Confirmed';
        break;
      case 'SHIPPED':
        bg = Colors.blue.shade900;
        fg = Colors.lightBlueAccent;
        label = '🚚 Shipped';
        break;
      case 'DELIVERED':
        bg = Colors.purple.shade900;
        fg = Colors.purpleAccent;
        label = '📦 Delivered';
        break;
      case 'CANCELLED':
        bg = Colors.red.shade900;
        fg = Colors.redAccent;
        label = '✗ Cancelled';
        break;
      default:
        bg = Colors.orange.shade900;
        fg = Colors.orangeAccent;
        label = '⏳ Processing';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _timelineItem(TrackingStep step, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: dot + line ─────────────────────────────────────────
          SizedBox(
            width: 36,
            child: Column(children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.isCompleted
                      ? Colors.greenAccent
                      : step.isActive
                          ? Colors.orangeAccent
                          : const Color(0xFF2A2A2A),
                  border: Border.all(
                    color: step.isCompleted
                        ? Colors.greenAccent
                        : step.isActive
                            ? Colors.orangeAccent
                            : const Color(0xFF444444),
                    width: 2,
                  ),
                ),
                child: step.isCompleted
                    ? const Icon(Icons.check, size: 12, color: Colors.black)
                    : step.isActive
                        ? const Icon(Icons.circle, size: 8, color: Colors.black)
                        : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: step.isCompleted
                        ? Colors.greenAccent.withOpacity(0.4)
                        : const Color(0xFF2A2A2A),
                  ),
                ),
            ]),
          ),

          const SizedBox(width: 14),

          // ── Right: text ───────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      color: step.isCompleted || step.isActive
                          ? Colors.white
                          : const Color(0xFF555555),
                      fontSize: 15,
                      fontWeight: step.isActive
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  if (step.subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      step.subtitle!,
                      style: TextStyle(
                        color: step.isCompleted || step.isActive
                            ? const Color(0xFF888888)
                            : const Color(0xFF444444),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (step.timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(step.timestamp!),
                      style: const TextStyle(
                          color: Color(0xFF555555), fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
          color: Color(0xFF555555),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4),
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(children: rows),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Text(label,
            style: const TextStyle(color: Color(0xFF666666), fontSize: 13)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _actionButtons(BuildContext context) {
    return Column(children: [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context, '/home', (r) => false),
          icon: const Icon(Icons.home_outlined),
          label: const Text('Continue Shopping'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/account/orders'),
          icon: const Icon(Icons.receipt_long_outlined, color: Colors.white),
          label: const Text('View All Orders',
              style: TextStyle(color: Colors.white)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF2A2A2A)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]);
  }

  String _formatTimestamp(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]}, $h:$m $ampm';
  }

  String _paymentLabel(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
      case 'COMPLETED':
        return 'Paid';
      case 'PENDING':
        return 'Pending';
      case 'FAILED':
        return 'Failed';
      default:
        return status;
    }
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../provider/orders_provider.dart';
import '../../utils/app_colors.dart';

class OrderDetailsPage extends ConsumerStatefulWidget {
  final String orderId; // bookingId from the route

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends ConsumerState<OrderDetailsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(orderDetailProvider(widget.orderId).notifier).fetchDetail());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: const Text('Order Details',
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(OrderDetailState state) {
    if (state.isLoading) return _buildSkeleton();

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.grey, size: 48),
              const SizedBox(height: 12),
              Text(state.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.grey, fontSize: 14)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref
                    .read(orderDetailProvider(widget.orderId).notifier)
                    .fetchDetail(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.bg),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final data = state.data;
    if (data == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _StatusHeader(data: data),
        _ItemsSection(data: data),
        _PaymentSummarySection(data: data),
        _TransactionsSection(
          data: data,
          bookingId: widget.orderId,
          onOtpGenerated: (otp, expiresIn) => _showOtpDialog(otp, expiresIn),
        ),
        _ReceiptButton(data: data, onDownload: _downloadReceipt),
      ],
    );
  }

  // ─── COD OTP Dialog ──────────────────────────────────────────────────────────

  void _showOtpDialog(String otp, int expiresInMinutes) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border)),
        title: const Text('Your Delivery OTP',
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                otp,
                style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 10),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined,
                    size: 14, color: AppColors.grey),
                const SizedBox(width: 5),
                Text('Expires in $expiresInMinutes minutes',
                    style: const TextStyle(
                        color: AppColors.grey, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Show this OTP to your delivery partner to confirm cash payment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey, fontSize: 12, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: otp));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('OTP copied'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ));
            },
            child: const Text('Copy OTP',
                style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(
                    color: AppColors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── Receipt Download ─────────────────────────────────────────────────────────
  // Calls GET /api/v1/receipt/{bookingId}/download.
  // The provider retries automatically on 404 (receipt not yet generated).

  Future<void> _downloadReceipt(Map<String, dynamic> data) async {
    final filePath = await ref
        .read(orderDetailProvider(widget.orderId).notifier)
        .downloadReceipt();

    if (!mounted) return;

    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Receipt is not ready yet. Please try again in a few seconds.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // Extract just the filename for the notification.
    final fileName = filePath.split('/').last.split('\\').last;

    // Try to open directly in a PDF viewer.
    final uri = Uri.file(filePath);
    final opened =
        await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(opened
            ? '$fileName downloaded'
            : '$fileName saved to Downloads'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: List.generate(
        4,
        (_) => Shimmer.fromColors(
          baseColor: AppColors.surface,
          highlightColor: AppColors.surface2,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Status Header Card ───────────────────────────────────────────────────────

class _StatusHeader extends StatelessWidget {
  final Map<String, dynamic> data;
  const _StatusHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    final statusLabel = data['statusLabel'] as String? ?? 'Order Placed';
    final status = data['status'] as String? ?? '';
    final bookingId = data['bookingId'] as String? ?? '—';
    final createdAt = data['createdAt'] as String?;
    final shortId = bookingId.length > 16
        ? '${bookingId.substring(0, 8)}…${bookingId.substring(bookingId.length - 4)}'
        : bookingId;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusDot(status: status),
              const SizedBox(width: 10),
              Text(statusLabel,
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(label: 'Order ID', value: shortId),
          if (createdAt != null) ...[
            const SizedBox(height: 6),
            _InfoRow(label: 'Placed on', value: _formatDate(createdAt)),
          ],
        ],
      ),
    );
  }
}

// ─── Items Section ────────────────────────────────────────────────────────────

class _ItemsSection extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ItemsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = (data['items'] as List<dynamic>?) ?? [];
    if (items.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Items Ordered'),
          const SizedBox(height: 14),
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value as Map<String, dynamic>;
            final qty = (item['quantity'] as num?)?.toInt() ?? 1;
            final unit = item['unitPriceRupees'] as String? ?? '—';
            final lineTotal = item['lineTotalRupees'] as String? ?? '—';

            return Column(
              children: [
                if (i > 0) ...[
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 8),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product icon placeholder
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined,
                          color: AppColors.greyDark, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Item ${i + 1}',
                              style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          const SizedBox(height: 3),
                          Text('Qty: $qty × ₹$unit',
                              style: const TextStyle(
                                  color: AppColors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                    Text('₹$lineTotal',
                        style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─── Payment Summary Section ──────────────────────────────────────────────────

class _PaymentSummarySection extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PaymentSummarySection({required this.data});

  @override
  Widget build(BuildContext context) {
    final payment = data['payment'] as Map<String, dynamic>?;
    final total = data['totalAmountRupees'] as String? ?? '—';

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Payment Summary'),
          const SizedBox(height: 14),
          _InfoRow(label: 'Order Total', value: '₹$total', bold: true),
          if (payment != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Paid Amount',
              value: '₹${payment['totalAmountRupees'] ?? '—'}',
            ),
            const SizedBox(height: 8),
            _PaymentStatusRow(status: payment['status'] as String? ?? ''),
          ] else ...[
            const SizedBox(height: 8),
            const _InfoRow(label: 'Payment', value: 'Not initiated'),
          ],
        ],
      ),
    );
  }
}

// ─── Transactions Section ─────────────────────────────────────────────────────

class _TransactionsSection extends StatelessWidget {
  final Map<String, dynamic> data;
  final String bookingId;
  final void Function(String otp, int expiresIn) onOtpGenerated;

  const _TransactionsSection({
    required this.data,
    required this.bookingId,
    required this.onOtpGenerated,
  });

  @override
  Widget build(BuildContext context) {
    final payment = data['payment'] as Map<String, dynamic>?;
    if (payment == null) return const SizedBox.shrink();

    final transactions = (payment['transactions'] as List<dynamic>?) ?? [];
    if (transactions.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Transaction Breakdown'),
          const SizedBox(height: 14),
          ...transactions.asMap().entries.map((entry) {
            final i = entry.key;
            final tx = entry.value as Map<String, dynamic>;
            final method = tx['method'] as String? ?? '—';
            final status = tx['status'] as String? ?? '—';
            final amount = tx['amountRupees'] as String? ?? '—';
            final txnId = tx['transactionId'] as String? ?? '';
            final createdAt = tx['createdAt'] as String?;
            final isCodPending =
                method == 'COD' && status == 'PENDING';

            return Column(
              children: [
                if (i > 0) ...[
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 10),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MethodBadge(method: method),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('₹$amount',
                              style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                          const SizedBox(height: 4),
                          _TxStatusChip(status: status),
                          if (createdAt != null) ...[
                            const SizedBox(height: 4),
                            Text(_formatDate(createdAt),
                                style: const TextStyle(
                                    color: AppColors.greyDark, fontSize: 11)),
                          ],
                          if (txnId.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Ref: ${txnId.length > 16 ? '${txnId.substring(0, 16)}…' : txnId}',
                              style: const TextStyle(
                                  color: AppColors.greyDark, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                // COD OTP button
                if (isCodPending && txnId.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _CodOtpButton(transactionId: txnId, bookingId: bookingId),
                ],
                const SizedBox(height: 4),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─── COD OTP Button ───────────────────────────────────────────────────────────

class _CodOtpButton extends ConsumerStatefulWidget {
  final String transactionId;
  final String bookingId;
  const _CodOtpButton(
      {required this.transactionId, required this.bookingId});

  @override
  ConsumerState<_CodOtpButton> createState() => _CodOtpButtonState();
}

class _CodOtpButtonState extends ConsumerState<_CodOtpButton> {
  bool _loading = false;

  Future<void> _generate() async {
    setState(() => _loading = true);
    final result = await ref
        .read(orderDetailProvider(widget.bookingId).notifier)
        .generateOtp(widget.transactionId);
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['error'] as String),
        backgroundColor: AppColors.surface2,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final otp = result['otp']?.toString() ?? '—';
    final expires = (result['expiresInMinutes'] as num?)?.toInt() ?? 10;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border)),
        title: const Text('Delivery OTP',
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(otp,
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 10)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined,
                    size: 14, color: AppColors.grey),
                const SizedBox(width: 5),
                Text('Expires in $expires minutes',
                    style: const TextStyle(
                        color: AppColors.grey, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Show this OTP to your delivery partner to confirm cash payment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.grey, fontSize: 12, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: otp));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('OTP copied'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ));
            },
            child: const Text('Copy',
                style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done',
                style: TextStyle(
                    color: AppColors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _generate,
        icon: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    color: AppColors.bg, strokeWidth: 2))
            : const Icon(Icons.lock_open_outlined, size: 18),
        label: Text(_loading ? 'Generating…' : 'Generate OTP'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.bg,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

// ─── Receipt Button ───────────────────────────────────────────────────────────

class _ReceiptButton extends StatefulWidget {
  final Map<String, dynamic> data;
  final Future<void> Function(Map<String, dynamic>) onDownload;
  const _ReceiptButton({required this.data, required this.onDownload});

  @override
  State<_ReceiptButton> createState() => _ReceiptButtonState();
}

class _ReceiptButtonState extends State<_ReceiptButton> {
  bool _loading = false;

  Future<void> _tap() async {
    setState(() => _loading = true);
    await widget.onDownload(widget.data);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _tap,
        icon: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    color: AppColors.grey, strokeWidth: 2))
            : const Icon(Icons.download_outlined, size: 18),
        label: Text(_loading ? 'Downloading…' : 'Download Receipt'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size.fromHeight(50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ─── Shared Helpers ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: AppColors.grey,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4));
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _InfoRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.grey, fontSize: 13)),
        const Spacer(),
        const SizedBox(width: 16),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
        ),
      ],
    );
  }
}

class _PaymentStatusRow extends StatelessWidget {
  final String status;
  const _PaymentStatusRow({required this.status});

  Color get _color {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return Colors.greenAccent;
      case 'FAILED':
      case 'REVERSED':
        return Colors.redAccent;
      case 'PENDING':
        return Colors.amber;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Payment Status',
            style: TextStyle(color: AppColors.grey, fontSize: 13)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: _color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(status,
              style: TextStyle(
                  color: _color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _MethodBadge extends StatelessWidget {
  final String method;
  const _MethodBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    final isCod = method == 'COD';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCod ? Colors.amber.withOpacity(0.12) : Colors.blueAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCod
              ? Colors.amber.withOpacity(0.4)
              : Colors.blueAccent.withOpacity(0.4),
        ),
      ),
      child: Text(method,
          style: TextStyle(
              color: isCod ? Colors.amber : Colors.blueAccent,
              fontSize: 11,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _TxStatusChip extends StatelessWidget {
  final String status;
  const _TxStatusChip({required this.status});

  Color get _color {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return Colors.greenAccent;
      case 'FAILED':
        return Colors.redAccent;
      case 'PENDING':
        return Colors.amber;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(status,
        style: TextStyle(
            color: _color, fontSize: 12, fontWeight: FontWeight.w600));
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  Color get _color {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return Colors.greenAccent;
      case 'INITIATED':
        return Colors.amber;
      case 'CANCELLED':
      case 'FAILED':
        return Colors.redAccent;
      case 'REVERSE':
        return Colors.orange;
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color,
        boxShadow: [BoxShadow(color: _color.withOpacity(0.5), blurRadius: 6)],
      ),
    );
  }
}

// ─── Shared date formatter ────────────────────────────────────────────────────

String _formatDate(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return '—';
  try {
    final dt = DateTime.parse(isoDate).toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour > 12
        ? dt.hour - 12
        : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$min $ampm';
  } catch (_) {
    return isoDate;
  }
}

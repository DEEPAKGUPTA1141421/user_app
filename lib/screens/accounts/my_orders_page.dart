import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../provider/orders_provider.dart';
import '../../utils/app_colors.dart';
import '../../core/widgets/app_loader.dart';

class MyOrdersPage extends ConsumerStatefulWidget {
  const MyOrdersPage({super.key});

  @override
  ConsumerState<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends ConsumerState<MyOrdersPage> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(ordersProvider.notifier).fetchOrders());
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(ordersProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    await ref.read(ordersProvider.notifier).fetchOrders(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('My Orders',
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: AppColors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.white,
        backgroundColor: AppColors.surface,
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(OrdersState state) {
    if (state.isLoading && state.orders.isEmpty) {
      return _buildSkeletonList();
    }

    if (state.error != null && state.orders.isEmpty) {
      return _buildError(state.error!);
    }

    if (state.orders.isEmpty) {
      return _buildEmpty();
    }

    return ListView.builder(
      controller: _scrollCtrl,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: state.orders.length + (state.hasNext ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.orders.length) {
          return _buildLoadMoreIndicator(state.isLoadingMore);
        }
        return OrderCard(order: state.orders[index]);
      },
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.grey, size: 48),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.grey, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refresh,
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

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 64, color: AppColors.greyDark),
                const SizedBox(height: 16),
                const Text('No orders yet',
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('Your placed orders will appear here',
                    style: TextStyle(color: AppColors.grey, fontSize: 14)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/home'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.bg,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12)),
                  child: const Text('Start Shopping'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadMoreIndicator(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: isLoading
            ? const AppSpinner(size: 24)
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.surface,
        highlightColor: AppColors.surface2,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: status badge + amount
              Row(
                children: [
                  _shimBox(90, 26, radius: 20),
                  const Spacer(),
                  _shimBox(60, 18),
                ],
              ),
              const SizedBox(height: 12),
              // Middle row: item count + payment mode
              Row(
                children: [
                  _shimBox(16, 14, radius: 4),
                  const SizedBox(width: 6),
                  _shimBox(60, 13),
                  const SizedBox(width: 14),
                  _shimBox(16, 14, radius: 4),
                  const SizedBox(width: 6),
                  _shimBox(90, 13),
                ],
              ),
              const SizedBox(height: 12),
              _shimBox(double.infinity, 1, radius: 0),
              const SizedBox(height: 12),
              // Bottom row: id/date + view details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimBox(100, 11),
                      const SizedBox(height: 4),
                      _shimBox(70, 12),
                    ],
                  ),
                  _shimBox(80, 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  /// When set, a "Get Help" button is shown; tapping calls this.
  final VoidCallback? onGetHelp;
  const OrderCard({super.key, required this.order, this.onGetHelp});

  @override
  Widget build(BuildContext context) {
    final bookingId = order['bookingId'] as String? ?? '';
    final statusLabel = order['statusLabel'] as String? ?? 'Order Placed';
    final status = order['status'] as String? ?? '';
    final itemCount = (order['itemCount'] as num?)?.toInt() ?? 0;
    final total = order['totalAmountRupees'] as String? ?? '0.00';
    final paymentMode = order['paymentMode'] as String? ?? '';
    final createdAt = order['createdAt'] as String?;
    final shortId = bookingId.length > 12
        ? bookingId.substring(0, 12).toUpperCase()
        : bookingId.toUpperCase();

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/order/$bookingId'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: status badge + amount
            Row(
              children: [
                OrderStatusBadge(status: status, label: statusLabel),
                const Spacer(),
                Text('₹$total',
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ],
            ),

            const SizedBox(height: 10),

            // Middle row: item count + payment mode
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    size: 14, color: AppColors.grey),
                const SizedBox(width: 5),
                Text(
                  '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                  style: const TextStyle(color: AppColors.grey, fontSize: 13),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.payment_outlined,
                    size: 14, color: AppColors.grey),
                const SizedBox(width: 5),
                Text(
                  _paymentModeLabel(paymentMode),
                  style: const TextStyle(color: AppColors.grey, fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),

            // Bottom row: date + view details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: $shortId…',
                        style: const TextStyle(
                            color: AppColors.greyDark, fontSize: 11)),
                    if (createdAt != null) ...[
                      const SizedBox(height: 2),
                      Text(_formatDate(createdAt),
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 12)),
                    ],
                  ],
                ),
                const Row(
                  children: [
                    Text('View Details',
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios,
                        size: 12, color: AppColors.white),
                  ],
                ),
              ],
            ),

            // "Get Help" row — only shown when onGetHelp is wired up
            if (onGetHelp != null) ...[
              const SizedBox(height: 10),
              Container(height: 1, color: AppColors.divider),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onGetHelp,
                child: const Row(
                  children: [
                    Icon(Icons.headset_mic_outlined,
                        size: 14, color: Color(0xFFFF5200)),
                    SizedBox(width: 6),
                    Text('Get Help for this order',
                        style: TextStyle(
                            color: Color(0xFFFF5200),
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _paymentModeLabel(String mode) {
    switch (mode) {
      case 'COD':
        return 'Cash on Delivery';
      case 'ONLINE':
        return 'Paid Online';
      case 'POINTS':
        return 'Loyalty Points';
      case 'MIXED':
        return 'Split Payment';
      case 'UNPAID':
        return 'Payment Pending';
      default:
        return mode.isNotEmpty ? mode : '—';
    }
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class OrderStatusBadge extends StatelessWidget {
  final String status;
  final String label;
  const OrderStatusBadge({super.key, required this.status, required this.label});

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
      case 'REVERSE_FAILED':
        return Colors.red.shade700;
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _color),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: _color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

Widget _shimBox(double w, double h, {double radius = 6}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

// ─── Order Card Skeleton ──────────────────────────────────────────────────────

/// Single shimmer placeholder that matches the [OrderCard] layout exactly.
/// Use inside a [Shimmer.fromColors] or standalone — it wraps its own shimmer.
class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surface2,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _shimBox(90, 26, radius: 20),
                const Spacer(),
                _shimBox(60, 18),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _shimBox(16, 14, radius: 4),
                const SizedBox(width: 6),
                _shimBox(60, 13),
                const SizedBox(width: 14),
                _shimBox(16, 14, radius: 4),
                const SizedBox(width: 6),
                _shimBox(90, 13),
              ],
            ),
            const SizedBox(height: 12),
            _shimBox(double.infinity, 1, radius: 0),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimBox(100, 11),
                    const SizedBox(height: 4),
                    _shimBox(70, 12),
                  ],
                ),
                _shimBox(80, 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

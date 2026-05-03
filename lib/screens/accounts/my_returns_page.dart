import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/return_provider.dart';
import '../../utils/app_colors.dart';
import '../../core/widgets/app_loader.dart';

class MyReturnsPage extends ConsumerStatefulWidget {
  const MyReturnsPage({super.key});

  @override
  ConsumerState<MyReturnsPage> createState() => _MyReturnsPageState();
}

class _MyReturnsPageState extends ConsumerState<MyReturnsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(returnProvider.notifier).loadReturns(refresh: true));
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(returnProvider);
      if (state.hasMore && !state.isLoading) {
        ref.read(returnProvider.notifier).loadReturns();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(returnProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: const Text('My Returns',
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: state.isLoading && state.returns.isEmpty
          ? const Center(child: AppSpinner())
          : state.error != null && state.returns.isEmpty
              ? _buildError(state.error!)
              : state.returns.isEmpty
                  ? _buildEmpty()
                  : _buildList(state),
    );
  }

  Widget _buildError(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.grey, size: 48),
              const SizedBox(height: 12),
              Text(msg,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: AppColors.grey, fontSize: 14)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref
                    .read(returnProvider.notifier)
                    .loadReturns(refresh: true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.bg),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.assignment_return_outlined,
                  color: AppColors.grey, size: 34),
            ),
            const SizedBox(height: 16),
            const Text('No Return Requests',
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('You haven\'t submitted any returns yet.',
                style: TextStyle(color: AppColors.grey, fontSize: 14)),
          ],
        ),
      );

  Widget _buildList(ReturnState state) {
    return RefreshIndicator(
      color: AppColors.white,
      backgroundColor: AppColors.surface,
      onRefresh: () =>
          ref.read(returnProvider.notifier).loadReturns(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: state.returns.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == state.returns.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: AppSpinner()),
            );
          }
          return _ReturnCard(item: state.returns[i]);
        },
      ),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  final ReturnItem item;
  const _ReturnCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pushNamed(
            context,
            '/account/returns/detail',
            arguments: item.id,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.reasonLabel,
                        style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(status: item.status, label: item.statusLabel),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Order #${_shortId(item.bookingId)}',
                  style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                      fontFamily: 'monospace'),
                ),
                if (item.description != null &&
                    item.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.greyDark, fontSize: 13),
                  ),
                ],
                if (item.adminNote != null && item.adminNote!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.admin_panel_settings_outlined,
                            size: 14, color: AppColors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.adminNote!,
                            style: const TextStyle(
                                color: AppColors.grey, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (item.evidenceImages.isNotEmpty) ...[
                      const Icon(Icons.image_outlined,
                          size: 13, color: AppColors.greyDark),
                      const SizedBox(width: 4),
                      Text('${item.evidenceImages.length} photo(s)',
                          style: const TextStyle(
                              color: AppColors.greyDark, fontSize: 12)),
                      const SizedBox(width: 12),
                    ],
                    const Spacer(),
                    if (item.createdAt != null)
                      Text(_formatDate(item.createdAt),
                          style: const TextStyle(
                              color: AppColors.greyDark, fontSize: 11)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        size: 16, color: AppColors.greyDark),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final String label;
  const _StatusChip({required this.status, required this.label});

  Color get _color {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.amber;
      case 'APPROVED':
      case 'PICKUP_SCHEDULED':
      case 'PICKED_UP':
        return Colors.blueAccent;
      case 'REFUNDED':
        return Colors.greenAccent;
      case 'REJECTED':
        return Colors.redAccent;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: _color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

String _shortId(String id) =>
    id.length > 16 ? '${id.substring(0, 8)}…${id.substring(id.length - 4)}' : id;

String _formatDate(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return '';
  try {
    final dt = DateTime.parse(isoDate).toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return '';
  }
}

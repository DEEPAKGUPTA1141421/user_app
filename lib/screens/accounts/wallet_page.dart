import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/wallet_provider.dart';
import '../../utils/app_colors.dart';
import '../../core/widgets/app_loader.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(walletProvider.notifier).loadBalance();
      ref.read(walletProvider.notifier).loadTransactions(refresh: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      final s = ref.read(walletProvider);
      if (s.hasMore && !s.isLoadingTx) {
        ref.read(walletProvider.notifier).loadTransactions();
      }
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: const Text('My Wallet',
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.white,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await ref.read(walletProvider.notifier).loadBalance();
          await ref.read(walletProvider.notifier).loadTransactions(refresh: true);
        },
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Balance card ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _BalanceCard(state: state),
            ),

            // ── Section header ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Row(
                  children: [
                    const Text('TRANSACTION HISTORY',
                        style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4)),
                    const Spacer(),
                    if (state.isLoadingTx && state.transactions.isEmpty)
                      const AppSpinner(size: 14),
                  ],
                ),
              ),
            ),

            // ── Transactions ─────────────────────────────────────────────────
            state.transactions.isEmpty && !state.isLoadingTx
                ? SliverToBoxAdapter(child: _emptyTx())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        if (i == state.transactions.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: AppSpinner()),
                          );
                        }
                        final tx = state.transactions[i];
                        final prevTx =
                            i > 0 ? state.transactions[i - 1] : null;
                        return _TxTile(tx: tx, prevTx: prevTx);
                      },
                      childCount: state.transactions.length +
                          (state.hasMore ? 1 : 0),
                    ),
                  ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _emptyTx() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            children: [
              Icon(Icons.receipt_long_outlined,
                  color: AppColors.greyDark, size: 36),
              SizedBox(height: 12),
              Text('No transactions yet',
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text(
                'Refunds and cashbacks will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
}

// ─── Balance Card ─────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final WalletState state;
  const _BalanceCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final balance = state.balance;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF111111)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_balance_wallet_outlined,
                          color: AppColors.green, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('Wallet Balance',
                        style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 20),
                if (state.isLoadingBalance)
                  const SizedBox(
                    height: 44,
                    child: AppSpinner(color: AppColors.green),
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text('₹',
                            style: TextStyle(
                                color: AppColors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        balance?.balanceRupees ?? '0.00',
                        style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    balance != null && balance.balancePaise > 0
                        ? 'Available to use at checkout'
                        : 'No balance yet — refunds will appear here',
                    style: const TextStyle(
                        color: AppColors.grey, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.green.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.info_outline,
                          size: 13, color: AppColors.green),
                      SizedBox(width: 6),
                      Text(
                        'Use at checkout to pay instantly',
                        style: TextStyle(
                            color: AppColors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
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

// ─── Transaction Tile ─────────────────────────────────────────────────────────

class _TxTile extends StatelessWidget {
  final WalletTx tx;
  final WalletTx? prevTx;
  const _TxTile({required this.tx, this.prevTx});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.isCredit;
    final amountColor =
        isCredit ? AppColors.green : Colors.redAccent;
    final sign = isCredit ? '+' : '−';

    final showDateHeader = prevTx == null ||
        !_sameDay(tx.createdAt, prevTx!.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDateHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(
              _formatDateHeader(tx.createdAt),
              style: const TextStyle(
                  color: AppColors.greyDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5),
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: amountColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _sourceIcon(tx.source),
                  color: amountColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.sourceLabel,
                        style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      tx.description ?? tx.typeLabel,
                      style: const TextStyle(
                          color: AppColors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tx.referenceId != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Ref: ${_shortRef(tx.referenceId!)}',
                        style: const TextStyle(
                            color: AppColors.greyDark,
                            fontSize: 10,
                            fontFamily: 'monospace'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sign ₹${tx.amountRupees}',
                    style: TextStyle(
                        color: amountColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatTime(tx.createdAt),
                    style: const TextStyle(
                        color: AppColors.greyDark, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _sourceIcon(String source) {
    switch (source) {
      case 'REFUND':
        return Icons.assignment_return_outlined;
      case 'PURCHASE':
        return Icons.shopping_bag_outlined;
      case 'CASHBACK':
        return Icons.percent_rounded;
      case 'REFERRAL':
        return Icons.people_outline_rounded;
      case 'ADMIN_CREDIT':
      case 'ADMIN_DEBIT':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  bool _sameDay(String? a, String? b) {
    if (a == null || b == null) return false;
    try {
      final da = DateTime.parse(a).toLocal();
      final db = DateTime.parse(b).toLocal();
      return da.year == db.year && da.month == db.month && da.day == db.day;
    } catch (_) {
      return false;
    }
  }

  String _formatDateHeader(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return 'Today';
      }
      final yesterday = now.subtract(const Duration(days: 1));
      if (dt.year == yesterday.year &&
          dt.month == yesterday.month &&
          dt.day == yesterday.day) {
        return 'Yesterday';
      }
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour > 12
          ? dt.hour - 12
          : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    } catch (_) {
      return '';
    }
  }

  String _shortRef(String ref) =>
      ref.length > 20 ? '${ref.substring(0, 10)}…${ref.substring(ref.length - 6)}' : ref;
}

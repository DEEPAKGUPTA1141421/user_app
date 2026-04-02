import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../provider/notification_preferences_provider.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  static const _bg = Color(0xFF0A0A0A);
  static const _surface = Color(0xFF141414);
  static const _surface2 = Color(0xFF1E1E1E);
  static const _border = Color(0xFF2A2A2A);
  static const _textPrimary = Colors.white;
  static const _textSecondary = Color(0xFF9A9A9A);
  static const _accent = Color(0xFFFF5200);

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(notificationPrefsProvider.notifier).fetchAll());
  }

  final Map<String, Map<String, dynamic>> _categoryMeta = {
    'ORDER_UPDATES': {
      'label': 'Order Updates',
      'desc': 'Order placed, shipped, delivered, cancelled',
      'icon': Icons.shopping_bag_outlined,
    },
    'PAYMENT_UPDATES': {
      'label': 'Payment Updates',
      'desc': 'Payment success, failure, refund initiated',
      'icon': Icons.payment_outlined,
    },
    'WALLET_UPDATES': {
      'label': 'Wallet Updates',
      'desc': 'Top-up, debit, low-balance alerts',
      'icon': Icons.account_balance_wallet_outlined,
    },
    'LOYALTY_UPDATES': {
      'label': 'Loyalty & Rewards',
      'desc': 'Points earned, tier upgrade, expiry warnings',
      'icon': Icons.star_outline,
    },
    'PROMOTIONS': {
      'label': 'Promotions',
      'desc': 'Deals, coupons, flash sales',
      'icon': Icons.local_offer_outlined,
    },
    'PRODUCT_UPDATES': {
      'label': 'Product Updates',
      'desc': 'Price drop, back-in-stock alerts',
      'icon': Icons.inventory_2_outlined,
    },
    'ACCOUNT_SECURITY': {
      'label': 'Account Security',
      'desc': 'Login OTP, password change, suspicious login',
      'icon': Icons.security_outlined,
    },
    'REVIEW_REMINDERS': {
      'label': 'Review Reminders',
      'desc': 'Remind to review purchased products',
      'icon': Icons.rate_review_outlined,
    },
    'SYSTEM_ALERTS': {
      'label': 'System Alerts',
      'desc': 'Downtime notices, policy updates',
      'icon': Icons.notifications_outlined,
    },
  };

  final List<String> _channels = ['EMAIL', 'SMS', 'PUSH', 'IN_APP'];

  Map<String, IconData> get _channelIcons => {
        'EMAIL': Icons.email_outlined,
        'SMS': Icons.sms_outlined,
        'PUSH': Icons.notifications_outlined,
        'IN_APP': Icons.notifications_active_outlined,
      };

  Map<String, String> get _channelLabels => {
        'EMAIL': 'Email',
        'SMS': 'SMS',
        'PUSH': 'Push',
        'IN_APP': 'In-App',
      };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationPrefsProvider);
    final isLoading = state['isLoading'] as bool? ?? false;
    final prefs = state['preferences'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _textPrimary,
        elevation: 0,
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!isLoading)
            TextButton(
              onPressed: () =>
                  ref.read(notificationPrefsProvider.notifier).fetchAll(),
              child: const Text('Refresh',
                  style: TextStyle(color: _accent, fontSize: 13)),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: isLoading && prefs.isEmpty
          ? _buildShimmer()
          : RefreshIndicator(
              color: _accent,
              backgroundColor: _surface,
              onRefresh: () =>
                  ref.read(notificationPrefsProvider.notifier).fetchAll(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Channel legend ──────────────────────────────────
                    Container(
                      color: _surface,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Row(
                        children: _channels.map((ch) {
                          return Expanded(
                            child: Column(
                              children: [
                                Icon(_channelIcons[ch],
                                    color: _textSecondary, size: 18),
                                const SizedBox(height: 3),
                                Text(
                                  _channelLabels[ch] ?? ch,
                                  style: const TextStyle(
                                    color: _textSecondary,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Container(height: 1, color: _border),

                    // ── Category rows ───────────────────────────────────
                    ..._categoryMeta.entries.map((entry) {
                      final category = entry.key;
                      final meta = entry.value;
                      final categoryPrefs =
                          (prefs[category] ?? []) as List<dynamic>;
                      return _CategoryRow(
                        category: category,
                        meta: meta,
                        prefs: categoryPrefs,
                        channels: _channels,
                        channelIcons: _channelIcons,
                        onToggle: (channel, enabled) async {
                          await ref
                              .read(notificationPrefsProvider.notifier)
                              .updateCategory(
                                category: category,
                                channel: channel,
                                enabled: enabled,
                              );
                        },
                      );
                    }),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildShimmer() {
    return Column(
      children: List.generate(
        6,
        (_) => Shimmer.fromColors(
          baseColor: const Color(0xFF1E1E1E),
          highlightColor: const Color(0xFF2A2A2A),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 80,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final Map<String, dynamic> meta;
  final List<dynamic> prefs;
  final List<String> channels;
  final Map<String, IconData> channelIcons;
  final void Function(String channel, bool enabled) onToggle;

  const _CategoryRow({
    required this.category,
    required this.meta,
    required this.prefs,
    required this.channels,
    required this.channelIcons,
    required this.onToggle,
  });

  static const _bg = Color(0xFF0A0A0A);
  static const _surface = Color(0xFF141414);
  static const _border = Color(0xFF2A2A2A);
  static const _textPrimary = Colors.white;
  static const _textSecondary = Color(0xFF9A9A9A);
  static const _accent = Color(0xFFFF5200);

  bool _isEnabled(String channel) {
    final pref = prefs.firstWhere(
      (p) => p['channel'] == channel,
      orElse: () => null,
    );
    return pref?['enabled'] == true;
  }

  bool _isLocked(String channel) {
    // ACCOUNT_SECURITY EMAIL/SMS cannot be disabled
    if (category == 'ACCOUNT_SECURITY' &&
        (channel == 'EMAIL' || channel == 'SMS')) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          // Category info
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    meta['icon'] as IconData,
                    color: _accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta['label'] as String,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meta['desc'] as String,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 10,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Channel toggles
          ...channels.map((ch) {
            final enabled = _isEnabled(ch);
            final locked = _isLocked(ch);
            return Expanded(
              flex: 1,
              child: Center(
                child: GestureDetector(
                  onTap: locked
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Security notifications cannot be disabled'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      : () => onToggle(ch, !enabled),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: locked
                          ? _accent.withOpacity(0.3)
                          : enabled
                              ? _accent
                              : const Color(0xFF2A2A2A),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: locked
                            ? _accent.withOpacity(0.5)
                            : enabled
                                ? _accent
                                : const Color(0xFF3A3A3A),
                        width: 1.5,
                      ),
                    ),
                    child: enabled || locked
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 13)
                        : null,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
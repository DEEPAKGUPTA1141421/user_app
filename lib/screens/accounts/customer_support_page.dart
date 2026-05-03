import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/orders_provider.dart';
import '../../provider/support_provider.dart';
import '../../utils/app_colors.dart';
import '../support/support_chat_screen.dart';
import 'my_orders_page.dart' show OrderCard, OrderCardSkeleton;

class CustomerSupportPage extends ConsumerStatefulWidget {
  const CustomerSupportPage({super.key});

  @override
  ConsumerState<CustomerSupportPage> createState() =>
      _CustomerSupportPageState();
}

class _CustomerSupportPageState extends ConsumerState<CustomerSupportPage> {
  static const _brand = Color(0xFFFF5200);

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(ordersProvider.notifier).fetchOrders(),
    );
  }

  // ── Issue picker: called when user taps an issue card (with or without order) ──

  void _showIssuePicker(
    BuildContext context, {
    Map<String, dynamic>? order,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _IssueCategorySheet(order: order, brandColor: _brand),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          '24×7 Customer Support',
          style: TextStyle(
              color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SupportBanner(brandColor: _brand),
            const SizedBox(height: 8),

            // ── Recent Orders ──────────────────────────────────────────────
            _SectionHeader(
              title: 'Need help with an order?',
              subtitle: 'Select an order to get targeted support',
            ),
            if (ordersState.isLoading && ordersState.orders.isEmpty)
              Container(
                color: AppColors.surface,
                child: Column(
                  children: List.generate(3, (_) => const OrderCardSkeleton()),
                ),
              )
            else if (ordersState.orders.isEmpty)
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text('No recent orders found',
                        style: TextStyle(color: AppColors.grey, fontSize: 13)),
                  ),
                ),
              )
            else
              Container(
                color: AppColors.surface,
                child: Column(
                  children: ordersState.orders.take(4).map((o) => OrderCard(
                    order: o,
                    onGetHelp: () => _showIssuePicker(context, order: o),
                  )).toList(),
                ),
              ),

            const SizedBox(height: 8),

            // ── Issue grid (general, no order context) ────────────────────
            _SectionHeader(
              title: 'What issue are you facing?',
              subtitle: 'Get help on any topic — no order needed',
            ),
            _IssueGrid(
              brandColor: _brand,
              onTap: (issue) => _showIssuePicker(context),
            ),

            const SizedBox(height: 8),

            // ── FAQs ───────────────────────────────────────────────────────
            _FaqSection(brandColor: _brand),
          ],
        ),
      ),
    );
  }
}

// ─── Support Hero Banner ───────────────────────────────────────────────────────

class _SupportBanner extends StatelessWidget {
  final Color brandColor;
  const _SupportBanner({required this.brandColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: brandColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.headset_mic_rounded, color: brandColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('We\'re here to help',
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Avg. response time: under 2 minutes',
                    style: TextStyle(color: AppColors.grey, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                SizedBox(width: 5),
                Text('Online',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(color: AppColors.grey, fontSize: 12)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ─── Issue Grid ────────────────────────────────────────────────────────────────

class _IssueGrid extends StatelessWidget {
  final Color brandColor;
  final void Function(SupportIssue) onTap;

  const _IssueGrid({required this.brandColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemCount: kSupportIssues.length,
        itemBuilder: (_, i) {
          final issue = kSupportIssues[i];
          return GestureDetector(
            onTap: () => onTap(issue),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(issue.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 6),
                  Text(
                    issue.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.white, fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── FAQ Section ───────────────────────────────────────────────────────────────

class _FaqSection extends StatelessWidget {
  final Color brandColor;
  const _FaqSection({required this.brandColor});

  static const _faqs = [
    ('How long does delivery take?', 'Standard delivery: 2–5 business days. Express: 1–2 days.'),
    ('How do I cancel an order?', 'You can cancel before it ships from My Orders → Order Details.'),
    ('When will I get my refund?', 'Refunds are processed within 5–7 business days after return pickup.'),
    ('How do I track my order?', 'Go to My Orders → Select order → Track Order.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Frequently Asked Questions',
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ..._faqs.map((faq) => _FaqTile(q: faq.$1, a: faq.$2)),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String q;
  final String a;
  const _FaqTile({required this.q, required this.a});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.q,
                        style: const TextStyle(
                            color: AppColors.white, fontSize: 13)),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.grey,
                    size: 18,
                  ),
                ],
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Text(widget.a,
                    style: const TextStyle(
                        color: AppColors.grey, fontSize: 12, height: 1.5)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Issue Category Bottom Sheet ───────────────────────────────────────────────

class _IssueCategorySheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? order;
  final Color brandColor;

  const _IssueCategorySheet({this.order, required this.brandColor});

  @override
  ConsumerState<_IssueCategorySheet> createState() =>
      _IssueCategorySheetState();
}

class _IssueCategorySheetState extends ConsumerState<_IssueCategorySheet> {
  SupportIssue? _selectedIssue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Order context chip
            if (widget.order != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined,
                        color: AppColors.grey, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Order: ${_orderLabel(widget.order!)}',
                        style: const TextStyle(
                            color: AppColors.grey, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Text('What issue are you facing?',
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),

            // Category grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.82,
                ),
                itemCount: kSupportIssues.length,
                itemBuilder: (_, i) {
                  final issue = kSupportIssues[i];
                  final selected = _selectedIssue?.key == issue.key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIssue = issue),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: selected
                            ? widget.brandColor.withOpacity(0.15)
                            : AppColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? widget.brandColor
                              : AppColors.border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(issue.emoji,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 5),
                          Text(
                            issue.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected
                                  ? widget.brandColor
                                  : AppColors.white,
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            if (_selectedIssue != null)
              _DescriptionSheet(
                issue: _selectedIssue!,
                order: widget.order,
                brandColor: widget.brandColor,
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _orderLabel(Map<String, dynamic> o) {
    final name = o['productName'] as String? ??
        o['items']?[0]?['name'] as String? ?? '';
    final raw = o['bookingId'] as String? ?? '';
    final id = raw.length > 8 ? raw.substring(0, 8) : raw;
    return name.isNotEmpty ? name : '#$id';
  }
}

// ─── Description + Start Chat ─────────────────────────────────────────────────

class _DescriptionSheet extends ConsumerStatefulWidget {
  final SupportIssue issue;
  final Map<String, dynamic>? order;
  final Color brandColor;

  const _DescriptionSheet({
    required this.issue,
    required this.order,
    required this.brandColor,
  });

  @override
  ConsumerState<_DescriptionSheet> createState() => _DescriptionSheetState();
}

class _DescriptionSheetState extends ConsumerState<_DescriptionSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _startChat() async {
    final orderId = widget.order?['bookingId'] as String?;
    final ticket = await ref.read(supportProvider.notifier).startSupportChat(
          issue: widget.issue.label,
          category: widget.issue.key,
          orderId: orderId,
          description: _ctrl.text.trim(),
        );

    if (!mounted) return;

    if (ticket == null) {
      final error = ref.read(supportProvider).error ?? 'Failed to start chat';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final chatToken = ref.read(supportProvider).chatToken!;

    // Close the bottom sheet
    Navigator.pop(context);

    // Open the chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupportChatScreen(
          channelUrl: ticket.channelUrl,
          ticketId: ticket.ticketId,
          sendbirdUserId: chatToken.sendbirdUserId,
          sessionToken: chatToken.sessionToken,
          issueLabel: widget.issue.label,
          orderLabel: widget.order != null
              ? _orderLabel(widget.order!)
              : null,
        ),
      ),
    );
  }

  String _orderLabel(Map<String, dynamic> o) {
    final name = o['productName'] as String? ??
        o['items']?[0]?['name'] as String? ?? '';
    final raw = o['bookingId'] as String? ?? '';
    final id = raw.length > 8 ? raw.substring(0, 8) : raw;
    return name.isNotEmpty ? name : '#$id';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            color: AppColors.divider,
            margin: const EdgeInsets.only(bottom: 16),
          ),
          Text(
            '${widget.issue.emoji}  ${widget.issue.label}',
            style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            style: const TextStyle(color: AppColors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Describe your issue (optional)…',
              hintStyle:
                  const TextStyle(color: AppColors.grey, fontSize: 13),
              filled: true,
              fillColor: AppColors.surface2,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: widget.brandColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: state.isLoading ? null : _startChat,
              icon: state.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: Text(
                state.isLoading ? 'Connecting…' : 'Start Chat with Support',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.brandColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

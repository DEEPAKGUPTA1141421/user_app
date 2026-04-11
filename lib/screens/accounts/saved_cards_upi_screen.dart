import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../provider/saved_payment_methods_provider.dart';

class SavedCardsUpiScreen extends ConsumerStatefulWidget {
  const SavedCardsUpiScreen({super.key});

  @override
  ConsumerState<SavedCardsUpiScreen> createState() =>
      _SavedCardsUpiScreenState();
}

class _SavedCardsUpiScreenState extends ConsumerState<SavedCardsUpiScreen>
    with SingleTickerProviderStateMixin {
  static const brandColor = Colors.black;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(
        () => ref.read(savedPaymentMethodsProvider.notifier).fetchAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddCardSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddCardSheet(),
    );
  }

  void _showAddUpiSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddUpiSheet(),
    );
  }

  Future<void> _deleteMethod(String id, String label) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Payment Method'),
        content: Text('Remove "$label" from your saved methods?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final res =
          await ref.read(savedPaymentMethodsProvider.notifier).delete(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['success'] == true
              ? 'Removed successfully'
              : res['message'] ?? 'Failed'),
          backgroundColor:
              res['success'] == true ? Colors.green : Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savedPaymentMethodsProvider);
    final isLoading = state.isLoading;
    final methods = state.methods;

    final cards = methods
        .where((m) => m['methodType'] == 'CARD')
        .toList();
    final upis = methods
        .where((m) => m['methodType'] == 'UPI')
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Saved Cards & UPI'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[400],
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Cards (${cards.length})'),
            Tab(text: 'UPI (${upis.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── CARDS TAB ──────────────────────────────────────────────────
          RefreshIndicator(
            onRefresh: () =>
                ref.read(savedPaymentMethodsProvider.notifier).fetchAll(),
            child: isLoading && methods.isEmpty
                ? _buildShimmer()
                : _buildCardsList(cards),
          ),
          // ── UPI TAB ────────────────────────────────────────────────────
          RefreshIndicator(
            onRefresh: () =>
                ref.read(savedPaymentMethodsProvider.notifier).fetchAll(),
            child: isLoading && methods.isEmpty
                ? _buildShimmer()
                : _buildUpiList(upis),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: _tabController.index == 0
            ? _showAddCardSheet
            : _showAddUpiSheet,
        icon: const Icon(Icons.add),
        label: AnimatedBuilder(
          animation: _tabController,
          builder: (_, __) => Text(
            _tabController.index == 0 ? 'Add Card' : 'Add UPI',
          ),
        ),
      ),
    );
  }

  Widget _buildCardsList(List<dynamic> cards) {
    if (cards.isEmpty) {
      return _buildEmpty(
        icon: Icons.credit_card_outlined,
        title: 'No saved cards',
        subtitle: 'Add a debit or credit card for faster checkout',
        onAdd: _showAddCardSheet,
        label: 'Add Card',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: cards.length,
      itemBuilder: (context, i) =>
          _CardTile(method: cards[i], onDelete: _deleteMethod),
    );
  }

  Widget _buildUpiList(List<dynamic> upis) {
    if (upis.isEmpty) {
      return _buildEmpty(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No saved UPI IDs',
        subtitle: 'Save your UPI ID for instant payments',
        onAdd: _showAddUpiSheet,
        label: 'Add UPI ID',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: upis.length,
      itemBuilder: (context, i) =>
          _UpiTile(method: upis[i], onDelete: _deleteMethod),
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onAdd,
    required String label,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 52, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ─── Card Tile ────────────────────────────────────────────────────────────────
class _CardTile extends StatelessWidget {
  final Map<String, dynamic> method;
  final Future<void> Function(String id, String label) onDelete;

  const _CardTile({required this.method, required this.onDelete});

  IconData _brandIcon(String? brand) {
    switch ((brand ?? '').toUpperCase()) {
      case 'VISA':
        return Icons.credit_card;
      case 'MASTERCARD':
        return Icons.credit_card;
      default:
        return Icons.credit_card_outlined;
    }
  }

  Color _brandColor(String? brand) {
    switch ((brand ?? '').toUpperCase()) {
      case 'VISA':
        return const Color(0xFF1A1F71);
      case 'MASTERCARD':
        return const Color(0xFFEB001B);
      case 'RUPAY':
        return const Color(0xFF017C3C);
      case 'AMEX':
        return const Color(0xFF016FD0);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDefault = method['isDefault'] == true;
    final brand = method['cardBrand'] as String? ?? '';
    final last4 = method['cardLast4'] as String? ?? '****';
    final expiry = method['cardExpiry'] as String? ?? '';
    final holder = method['cardHolderName'] as String? ?? '';
    final type = method['cardType'] as String? ?? '';
    final nick = method['nickname'] as String?;
    final label = nick ?? '$brand ••••$last4';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDefault ? Colors.black : Colors.grey.shade200,
          width: isDefault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Card header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _brandColor(brand),
                  _brandColor(brand).withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(_brandIcon(brand), color: Colors.white, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        brand.isEmpty ? 'Card' : brand,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      Text(
                        '•••• •••• •••• $last4',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Default',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          // Card details
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (holder.isNotEmpty)
                        Text(holder,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (type.isNotEmpty)
                            _chip(type),
                          const SizedBox(width: 6),
                          if (expiry.isNotEmpty)
                            Text('Exp: $expiry',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => onDelete(
                      method['id']?.toString() ?? '', label),
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 10, color: Colors.black54)),
      );
}

// ─── UPI Tile ─────────────────────────────────────────────────────────────────
class _UpiTile extends StatelessWidget {
  final Map<String, dynamic> method;
  final Future<void> Function(String id, String label) onDelete;

  const _UpiTile({required this.method, required this.onDelete});

  String _bankShortName(String upiId) {
    final parts = upiId.split('@');
    return parts.length > 1 ? parts[1].toUpperCase() : 'UPI';
  }

  @override
  Widget build(BuildContext context) {
    final isDefault = method['isDefault'] == true;
    final upiId = method['upiId'] as String? ?? '';
    final displayName = method['upiDisplayName'] as String?;
    final nick = method['nickname'] as String?;
    final label = nick ?? upiId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDefault ? Colors.black : Colors.grey.shade200,
          width: isDefault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '@',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700]),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      upiId,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Default',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  displayName ?? _bankShortName(upiId),
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                onDelete(method['id']?.toString() ?? '', label),
            icon: const Icon(Icons.delete_outline,
                color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─── Add Card Sheet ───────────────────────────────────────────────────────────
class _AddCardSheet extends ConsumerStatefulWidget {
  const _AddCardSheet();

  @override
  ConsumerState<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends ConsumerState<_AddCardSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tokenCtrl = TextEditingController();
  final _last4Ctrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  String _brand = 'VISA';
  String _cardType = 'DEBIT';
  String _gateway = 'razorpay';
  bool _makeDefault = false;
  bool _loading = false;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _last4Ctrl.dispose();
    _holderCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final res = await ref.read(savedPaymentMethodsProvider.notifier).saveCard(
          gatewayToken: _tokenCtrl.text.trim(),
          cardLast4: _last4Ctrl.text.trim(),
          cardBrand: _brand,
          cardHolderName: _holderCtrl.text.trim(),
          cardExpiry: _expiryCtrl.text.trim(),
          cardType: _cardType,
          gateway: _gateway,
          makeDefault: _makeDefault,
        );
    setState(() => _loading = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['success'] == true
            ? 'Card saved successfully'
            : res['message'] ?? 'Failed'),
        backgroundColor:
            res['success'] == true ? Colors.green : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheet(
      title: 'Add New Card',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _field(_tokenCtrl, 'Gateway Token',
                hint: 'e.g. pay_XXXXXX (from Razorpay)',
                validator: (v) =>
                    v == null || v.length < 10 ? 'Enter valid token' : null),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _field(_last4Ctrl, 'Last 4 Digits',
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      validator: (v) => v == null || v.length != 4
                          ? 'Enter 4 digits'
                          : null),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_expiryCtrl, 'Expiry (MM/YYYY)',
                      hint: '08/2028',
                      validator: (v) => v == null || !v.contains('/')
                          ? 'Enter MM/YYYY'
                          : null),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _field(_holderCtrl, 'Card Holder Name',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter name' : null),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _dropdown('Brand', _brand, const [
                  'VISA', 'MASTERCARD', 'RUPAY', 'AMEX', 'DINERS'
                ], (v) => setState(() => _brand = v!))),
                const SizedBox(width: 12),
                Expanded(child: _dropdown('Card Type', _cardType, const [
                  'DEBIT', 'CREDIT', 'PREPAID'
                ], (v) => setState(() => _cardType = v!))),
              ],
            ),
            const SizedBox(height: 14),
            _dropdown('Gateway', _gateway, const [
              'razorpay', 'stripe', 'payu', 'cashfree', 'ccavenue'
            ], (v) => setState(() => _gateway = v!)),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _makeDefault,
              onChanged: (v) => setState(() => _makeDefault = v),
              title: const Text('Set as Default',
                  style: TextStyle(fontSize: 14)),
              activeColor: Colors.black,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save Card',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add UPI Sheet ────────────────────────────────────────────────────────────
class _AddUpiSheet extends ConsumerStatefulWidget {
  const _AddUpiSheet();

  @override
  ConsumerState<_AddUpiSheet> createState() => _AddUpiSheetState();
}

class _AddUpiSheetState extends ConsumerState<_AddUpiSheet> {
  final _formKey = GlobalKey<FormState>();
  final _upiCtrl = TextEditingController();
  final _displayCtrl = TextEditingController();
  final _nickCtrl = TextEditingController();
  bool _makeDefault = false;
  bool _loading = false;

  @override
  void dispose() {
    _upiCtrl.dispose();
    _displayCtrl.dispose();
    _nickCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final res =
        await ref.read(savedPaymentMethodsProvider.notifier).saveUpi(
              upiId: _upiCtrl.text.trim(),
              upiDisplayName: _displayCtrl.text.trim(),
              nickname: _nickCtrl.text.trim(),
              makeDefault: _makeDefault,
            );
    setState(() => _loading = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['success'] == true
            ? 'UPI ID saved'
            : res['message'] ?? 'Failed'),
        backgroundColor:
            res['success'] == true ? Colors.green : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheet(
      title: 'Add UPI ID',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _field(_upiCtrl, 'UPI ID',
                hint: 'yourname@upi',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter UPI ID';
                  if (!v.contains('@')) return 'Invalid format (user@bank)';
                  return null;
                }),
            const SizedBox(height: 14),
            _field(_displayCtrl, 'Bank / Display Name (optional)',
                hint: 'e.g. HDFC Bank'),
            const SizedBox(height: 14),
            _field(_nickCtrl, 'Nickname (optional)',
                hint: 'e.g. My PhonePe'),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _makeDefault,
              onChanged: (v) => setState(() => _makeDefault = v),
              title: const Text('Set as Default',
                  style: TextStyle(fontSize: 14)),
              activeColor: Colors.black,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save UPI ID',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _BottomSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const _BottomSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

TextFormField _field(
  TextEditingController ctrl,
  String label, {
  String? hint,
  TextInputType keyboardType = TextInputType.text,
  int? maxLength,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: ctrl,
    keyboardType: keyboardType,
    maxLength: maxLength,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
      counterText: '',
    ),
  );
}

Widget _dropdown(String label, String value, List<String> options,
    void Function(String?) onChanged) {
  return DropdownButtonFormField<String>(
    value: value,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
    items: options
        .map((o) => DropdownMenuItem(value: o, child: Text(o)))
        .toList(),
  );
}
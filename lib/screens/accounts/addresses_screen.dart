import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/rider_provider.dart';
import '../../widgets/current_location_button.dart';

// SAME COLORS AS EDIT PAGE
const _bg = Color(0xFF000000);
const _surface = Color(0xFF111111);
const _surface2 = Color(0xFF1A1A1A);
const _border = Color(0xFF2A2A2A);
const _white = Colors.white;
const _grey = Color(0xFF888888);
const _greyDark = Color(0xFF444444);

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(riderPod.notifier).getUserDetail());
  }

  Future<void> _setDefault(String addressId) async {
    final res = await ref.read(riderPod.notifier).makeAddressDefault(addressId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['success'] == true
                ? 'Default address updated'
                : res['message'] ?? 'Failed',
            style: const TextStyle(color: _white),
          ),
          backgroundColor: _surface2,
        ),
      );
    }
  }

  void _showAddAddressSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddAddressSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderPod);
    final isLoading = state['isLoading'] as bool? ?? false;
    final addresses = (state['user_detail']?['addresses'] ?? []) as List<dynamic>;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text('Saved Addresses',
            style: TextStyle(color: _white, fontSize: 17, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: _white),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAddressSheet,
        backgroundColor: _white,
        icon: const Icon(Icons.add_location_alt_outlined, color: _bg),
        label: const Text('Add Address', style: TextStyle(color: _bg)),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _white))
          : addresses.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: addresses.length,
                  itemBuilder: (context, i) {
                    final addr = addresses[i];
                    final isDefault = addr['default'] == true;

                    return _AddressCard(
                      address: addr,
                      isDefault: isDefault,
                      onSetDefault: () => _setDefault(addr['id']),
                    );
                  },
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off_outlined, size: 60, color: _grey),
          const SizedBox(height: 16),
          const Text('No addresses saved',
              style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Add your delivery addresses',
              style: TextStyle(color: _grey, fontSize: 13)),
          const SizedBox(height: 20),
          _OutlineButton(
            label: 'Add Address',
            onTap: _showAddAddressSheet,
          )
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Map<String, dynamic> address;
  final bool isDefault;
  final VoidCallback onSetDefault;

  const _AddressCard({
    required this.address,
    required this.isDefault,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final kind = address['kind'] ?? 'HOME';
    final line1 = address['line1'] ?? '';
    final city = address['city'] ?? '';
    final pincode = address['pincode'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDefault ? _white : _border,
          width: isDefault ? 1.3 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Icon(
              kind == 'WORK' ? Icons.work_outline : Icons.home_outlined,
              color: _grey,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(kind,
                style: const TextStyle(
                    color: _white, fontSize: 13, fontWeight: FontWeight.w600)),

            if (isDefault) ...[
              const SizedBox(width: 8),
              const Text('Default',
                  style: TextStyle(color: _grey, fontSize: 11)),
            ],

            const Spacer(),

            if (!isDefault)
              GestureDetector(
                onTap: onSetDefault,
                child: const Text('Set default',
                    style: TextStyle(color: _white, fontSize: 12)),
              )
          ],
        ),
        const SizedBox(height: 10),
        Text(line1,
            style: const TextStyle(color: _white, fontSize: 13)),
        if (city.isNotEmpty)
          Text('$city - $pincode',
              style: const TextStyle(color: _grey, fontSize: 12)),
      ]),
    );
  }
}

class _AddAddressSheet extends StatelessWidget {
  const _AddAddressSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Add New Address',
                style: TextStyle(
                    color: _white, fontSize: 16, fontWeight: FontWeight.w600)),

            const SizedBox(height: 20),

            const CurrentLocationButton(),

            const SizedBox(height: 20),

            const Text('or',
                style: TextStyle(color: _grey, fontSize: 12)),

            const SizedBox(height: 20),

            _OutlineButton(
              label: 'Enter Address Manually',
              onTap: () {
                Navigator.pop(context);
              },
            )
          ]),
        ),
      ),
    );
  }
}

// SAME BUTTON STYLE
class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _white),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: _white, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/rider_provider.dart';
import '../../widgets/current_location_button.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  static const brandColor = Color(0xFFFF5200);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(riderPod.notifier).getUserDetail());
  }

  Future<void> _setDefault(String addressId) async {
    final res = await ref.read(riderPod.notifier).makeAddressDefault(addressId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['success'] == true
            ? 'Default address updated'
            : res['message'] ?? 'Failed to update'),
        backgroundColor: res['success'] == true ? Colors.green : Colors.red,
      ));
    }
  }

  void _showAddAddressSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddAddressSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final riderState = ref.watch(riderPod);
    final isLoading = riderState['isLoading'] as bool? ?? false;
    final userDetail = riderState['user_detail'] ?? {};
    final addresses = (userDetail['addresses'] ?? []) as List<dynamic>;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Saved Addresses'),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAddressSheet,
        backgroundColor: brandColor,
        icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
        label: const Text('Add Address', style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: brandColor))
          : addresses.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final addr = addresses[index] as Map<String, dynamic>;
                    final isDefault = addr['default'] == true || addr['isDefault'] == true;

                    return _AddressCard(
                      address: addr,
                      isDefault: isDefault,
                      onSetDefault: () => _setDefault(addr['id']?.toString() ?? ''),
                    );
                  },
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No addresses saved', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Add your delivery addresses here', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddAddressSheet,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Add Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
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
    const brandColor = Color(0xFFFF5200);
    final kind = address['kind']?.toString() ?? 'HOME';
    final line1 = address['line1']?.toString() ?? '';
    final city = address['city']?.toString() ?? '';
    final pincode = address['pincode']?.toString() ?? '';
    final phone = address['phone']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDefault ? brandColor.withOpacity(0.4) : Colors.grey[200]!,
          width: isDefault ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                kind == 'WORK' ? Icons.work_outline : Icons.home_outlined,
                color: isDefault ? brandColor : Colors.grey[600],
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                kind,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDefault ? brandColor : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: brandColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Default', style: TextStyle(fontSize: 10, color: brandColor, fontWeight: FontWeight.w600)),
                ),
              const Spacer(),
              if (!isDefault)
                GestureDetector(
                  onTap: onSetDefault,
                  child: Text(
                    'Set as Default',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(line1, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          if (city.isNotEmpty || pincode.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('$city${pincode.isNotEmpty ? ' - $pincode' : ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          if (phone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(phone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}

class _AddAddressSheet extends ConsumerWidget {
  const _AddAddressSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Text('Add New Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CurrentLocationButton(),
                  const SizedBox(height: 16),
                  const Text('or enter manually', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to manual address form
                    },
                    icon: const Icon(Icons.edit_location_outlined),
                    label: const Text('Enter Address Manually'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black87,
                      minimumSize: const Size.fromHeight(48),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

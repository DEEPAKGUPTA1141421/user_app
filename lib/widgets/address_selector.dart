import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/rider_provider.dart';
import './current_location_button.dart';

class DeliveryAddressSelector extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  final ValueChanged<Map<String, dynamic>>? onAddressSelect;

  const DeliveryAddressSelector({
    super.key,
    this.onClose,
    this.onAddressSelect,
  });

  @override
  ConsumerState<DeliveryAddressSelector> createState() =>
      _DeliveryAddressSelectorState();
}

class _DeliveryAddressSelectorState
    extends ConsumerState<DeliveryAddressSelector> {
  String searchQuery = '';
  List<Map<String, dynamic>> addresses = [];

  /// ✅ Function to call API for setting default address
  Future<void> makeAddressDefault(String addressId) async {
    final res =
        await ref.read(riderPod.notifier).makeAddressDefault(addressId);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Address set as default successfully"),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh user details after updating default address
      await ref.read(riderPod.notifier).getUserDetail();

      setState(() {
        for (var addr in addresses) {
          addr['default'] = addr['id'] == addressId;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(res['message'] ?? "Failed to set default address"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final riderState = ref.watch(riderPod);
    final userDetail = riderState['user_detail'] ?? {};
    final addressesData = (userDetail['addresses'] ?? []) as List;

    // Initialize addresses once from API
    if (addresses.isEmpty && addressesData.isNotEmpty) {
      addresses = addressesData
          .map<Map<String, dynamic>>((a) => a as Map<String, dynamic>)
          .toList();
    }

    // Filter search results
    final filteredAddresses = addresses.where((addr) {
      final q = searchQuery.toLowerCase();
      final line1 = (addr['line1'] ?? '').toLowerCase();
      final kind = (addr['kind'] ?? '').toLowerCase();
      return line1.contains(q) || kind.contains(q);
    }).toList();

    void handleAddressSelect(String selectedId) {
      setState(() {
        addresses = addresses.map((addr) {
          addr['default'] = addr['id'] == selectedId;
          return addr;
        }).toList();
      });
      final selectedAddress =
          addresses.firstWhere((addr) => addr['id'] == selectedId);
      widget.onAddressSelect?.call(selectedAddress);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const CurrentLocationButton(),
            _buildSavedAddressesTitle(),
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filteredAddresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final address = filteredAddresses[index];
                  return _buildAddressCard(address, handleAddressSelect);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Select delivery address",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onClose,
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: "Search by area, street name, pin code",
          filled: true,
          fillColor: const Color(0xFFFF5200).withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFFFF5200),
              width: 2,
            ),
          ),
        ),
        onChanged: (value) => setState(() => searchQuery = value),
      ),
    );
  }

  Widget _buildSavedAddressesTitle() {
    void handleAddNewAddress() {
      debugPrint('Add New Address tapped');
      // You can trigger navigation to "Add Address" screen here
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Saved addresses",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          TextButton.icon(
            onPressed: handleAddNewAddress,
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Add New"),
          )
        ],
      ),
    );
  }

  Widget _buildAddressCard(
      Map<String, dynamic> address, void Function(String) onSelect) {
    final isSelected = address['default'] ?? false;

    return InkWell(
      onTap: () => onSelect(address['id']),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF5200).withOpacity(0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF5200)
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.home, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((address['kind'] ?? '').isNotEmpty)
                    Text(
                      address['kind'],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    address['line1'] ?? '',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => makeAddressDefault(address['id']),
              icon: const Icon(Icons.more_horiz),
            ),
          ],
        ),
      ),
    );
  }
}

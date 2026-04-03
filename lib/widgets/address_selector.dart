import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/rider_provider.dart';
import './current_location_button.dart';
import '../utils/app_colors.dart';

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

  Future<void> makeAddressDefault(String addressId) async {
    final res =
        await ref.read(riderPod.notifier).makeAddressDefault(addressId);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Default address updated"),
          backgroundColor: AppColors.surface2,
        ),
      );

      await ref.read(riderPod.notifier).getUserDetail();

      setState(() {
        for (var addr in addresses) {
          addr['default'] = addr['id'] == addressId;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? "Failed"),
          backgroundColor: AppColors.surface2,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final riderState = ref.watch(riderPod);
    final userDetail = riderState['user_detail'] ?? {};
    final addressesData = (userDetail['addresses'] ?? []) as List;

    if (addresses.isEmpty && addressesData.isNotEmpty) {
      addresses = addressesData
          .map<Map<String, dynamic>>((a) => a as Map<String, dynamic>)
          .toList();
    }

    final filteredAddresses = addresses.where((addr) {
      final q = searchQuery.toLowerCase();
      return (addr['line1'] ?? '').toLowerCase().contains(q) ||
          (addr['kind'] ?? '').toLowerCase().contains(q);
    }).toList();

    void handleAddressSelect(String selectedId) {
      setState(() {
        addresses = addresses.map((addr) {
          addr['default'] = addr['id'] == selectedId;
          return addr;
        }).toList();
      });

      final selected =
          addresses.firstWhere((addr) => addr['id'] == selectedId);

      widget.onAddressSelect?.call(selected);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const CurrentLocationButton(),
            _buildSavedAddressesTitle(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filteredAddresses.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
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

  // ───────────────── HEADER ─────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "Select delivery address",
              style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.onClose,
            child: const Icon(CupertinoIcons.xmark, color: AppColors.white, size: 20),
          )
        ],
      ),
    );
  }

  // ───────────────── SEARCH ─────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        style: const TextStyle(color: AppColors.white),
        decoration: InputDecoration(
          prefixIcon: const Icon(CupertinoIcons.search, color: AppColors.grey),
          hintText: "Search area, street, pincode",
          hintStyle: const TextStyle(color: AppColors.greyDark),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.white),
          ),
        ),
        onChanged: (v) => setState(() => searchQuery = v),
      ),
    );
  }

  // ───────────────── TITLE ─────────────────
  Widget _buildSavedAddressesTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "SAVED ADDRESSES",
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Row(
              children: [
                Icon(CupertinoIcons.add, size: 16, color: AppColors.white),
                SizedBox(width: 4),
                Text(
                  "Add New",
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // ───────────────── CARD ─────────────────
  Widget _buildAddressCard(
      Map<String, dynamic> address, Function(String) onSelect) {
    final isSelected = address['default'] ?? false;
    final kind = address['kind'] ?? 'HOME';

    return GestureDetector(
      onTap: () => onSelect(address['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.white : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              kind == 'WORK'
                  ? CupertinoIcons.briefcase
                  : CupertinoIcons.house,
              color: isSelected ? AppColors.white : AppColors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kind,
                    style: TextStyle(
                      color: isSelected ? AppColors.white : AppColors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    address['line1'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            if (isSelected)
              const Icon(
                CupertinoIcons.check_mark_circled_solid,
                color: AppColors.white,
                size: 20,
              )
            else
              GestureDetector(
                onTap: () => makeAddressDefault(address['id']),
                child: const Icon(
                  CupertinoIcons.ellipsis,
                  color: AppColors.grey,
                ),
              )
          ],
        ),
      ),
    );
  }
}
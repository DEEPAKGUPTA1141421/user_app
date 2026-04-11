import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/rider_provider.dart';
import '../utils/app_colors.dart';

class AddressSection extends ConsumerStatefulWidget {
  final VoidCallback showAddressModal;
  const AddressSection({super.key, required this.showAddressModal});

  @override
  ConsumerState<AddressSection> createState() => _AddressSectionState();
}

class _AddressSectionState extends ConsumerState<AddressSection> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(riderPod.notifier).getUserDetail();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rider = ref.watch(riderPod);
    final isLoading = rider.isLoading;

    // 🔹 Skeleton (dark theme)
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 80, height: 14, color: AppColors.surface2),
                  const SizedBox(height: 6),
                  Container(width: 140, height: 12, color: AppColors.surface),
                ],
              ),
            ]),
            Container(width: 40, height: 16, color: AppColors.surface2),
          ],
        ),
      );
    }

    final addresses = rider.addresses;

    final defaultAddress = addresses.isNotEmpty
        ? addresses.firstWhere(
            (a) => a['default'] == true,
            orElse: () => addresses.first,
          )
        : null;

    final line1 = defaultAddress?['line1'] ?? 'Select delivery location';
    final pincode = defaultAddress?['pincode'] ?? '';

    final displayText = line1.length > 28
        ? '$pincode, ${line1.substring(0, 28)}...'
        : line1;

    return GestureDetector(
      onTap: widget.showAddressModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.bg,
          border: Border(
            bottom: BorderSide(color: AppColors.divider),
          ),
        ),
        child: Row(
          children: [
            // 📍 Location Icon (Premium style)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                CupertinoIcons.location_solid,
                size: 18,
                color: AppColors.white,
              ),
            ),

            const SizedBox(width: 12),

            // 📍 Address text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Tap to change location",
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // 👉 Right side (arrow instead of coins → ecommerce style)
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.grey,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
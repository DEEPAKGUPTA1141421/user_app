import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/rider_provider.dart'; // adjust path

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
    // Fetch user details when this widget is mounted
    Future.microtask(() {
      ref.read(riderPod.notifier).getUserDetail();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rider = ref.watch(riderPod);
    final isLoading = rider['isLoading'] ?? false;

    // Skeleton placeholder
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side skeleton
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 14,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 140,
                      height: 12,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ],
            ),
            // Right side skeleton
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(width: 4),
                Container(
                  width: 20,
                  height: 14,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Actual content
    final userDetail = rider['user_detail'] ?? {};
    final addresses = (userDetail['addresses'] ?? []) as List;
    final defaultAddress = addresses.isNotEmpty
        ? addresses.firstWhere(
            (a) => a['default'] == true,
            orElse: () => addresses.first,
          )
        : null;

    final line1 = defaultAddress?['line1'] ?? 'Select delivery location';
    final truncatedLine1 = line1.length > 24
        ? '${defaultAddress?['pincode']}' ' ' ' ${line1.substring(0, 24)}...'
        : line1;
    final line2 = 'Select delivery location';
    final Color primaryOrange = const Color.fromRGBO(255, 82, 0, 1);

    return GestureDetector(
      onTap: widget.showAddressModal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side - Location
            Row(
              children: [
                const Icon(
                  CupertinoIcons.map_pin_ellipse,
                  size: 20,
                  color: Colors.black,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      truncatedLine1,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      line2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Right side - Coins
            Row(
              children: [
                Icon(
                  CupertinoIcons.bitcoin_circle,
                  size: 18,
                  color: primaryOrange,
                ),
                const SizedBox(width: 4),
                Text(
                  "0",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/rider_provider.dart';
import '../../utils/app_colors.dart';

class DeliveryInfo extends ConsumerWidget {
  final int deliveryDays;
  final String brandName;
  final bool freeDelivery;

  const DeliveryInfo({
    super.key,
    this.deliveryDays = 5,
    this.brandName = '',
    this.freeDelivery = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(riderPod).user;
    final addresses = user['addresses'] as List? ?? [];

    Map<String, dynamic>? defaultAddr;
    for (final a in addresses) {
      if (a['default'] == true) {
        defaultAddr = Map<String, dynamic>.from(a as Map);
        break;
      }
    }
    defaultAddr ??= addresses.isNotEmpty
        ? Map<String, dynamic>.from(addresses.first as Map)
        : null;

    final city = defaultAddr?['city'] as String? ?? '';
    final state = defaultAddr?['state'] as String? ?? '';
    final pincode = defaultAddr?['pincode'] as String? ?? '';
    final line1 = defaultAddr?['line1'] as String? ?? '';
    final deliveryDate = _formatDate(deliveryDays);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          const Text('Delivery Details',
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),

          const SizedBox(height: 14),

          // ── Address card ─────────────────────────────────────────────
          defaultAddr != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(CupertinoIcons.location_solid,
                            color: AppColors.green, size: 15),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (city.isNotEmpty)
                              Text(
                                '$city, $state – $pincode',
                                style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            if (line1.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                line1.length > 55
                                    ? '${line1.substring(0, 55)}…'
                                    : line1,
                                style: const TextStyle(
                                    color: AppColors.grey,
                                    fontSize: 11,
                                    height: 1.4),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(CupertinoIcons.chevron_right,
                          color: AppColors.grey, size: 14),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add_location_alt_outlined,
                            color: AppColors.green, size: 18),
                        SizedBox(width: 10),
                        Text('Add a delivery address',
                            style: TextStyle(
                                color: AppColors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                ),

          const SizedBox(height: 14),

          // ── Delivery estimate ─────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.local_shipping_outlined,
                  color: AppColors.green, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      freeDelivery
                          ? 'Free Delivery by $deliveryDate'
                          : 'Delivery by $deliveryDate',
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      freeDelivery
                          ? 'No extra charges on this order'
                          : 'Standard delivery charges apply',
                      style: const TextStyle(
                          color: AppColors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          // ── Fulfilled by Dashly ───────────────────────────────────────
          Row(
            children: [
              const Icon(CupertinoIcons.checkmark_seal_fill,
                  color: AppColors.green, size: 15),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, height: 1.5),
                    children: [
                      TextSpan(
                        text: brandName.isNotEmpty
                            ? 'Sold by $brandName'
                            : 'Sold on Dashly',
                        style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(
                        text: ' · Fulfilled by ',
                        style: TextStyle(color: AppColors.grey),
                      ),
                      const TextSpan(
                        text: 'Dashly',
                        style: TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(int days) {
    final date = DateTime.now().add(Duration(days: days));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${date.day} ${months[date.month - 1]}, ${weekdays[date.weekday - 1]}';
  }
}

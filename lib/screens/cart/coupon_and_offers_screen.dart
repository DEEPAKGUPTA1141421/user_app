import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'coupon_screen.dart';

class CouponAndOffersCard extends StatelessWidget {
  final VoidCallback? onApply;
  final VoidCallback? onBuy;
  final VoidCallback? onRemove;
  final double totalDiscount;
  final double deliveryCharge;
  final Map<String, dynamic>? membershipOffer;
  final bool membershipAdded;

  const CouponAndOffersCard({
    super.key,
    this.onApply,
    this.onBuy,
    this.onRemove,
    this.totalDiscount = 0,
    this.deliveryCharge = 0,
    this.membershipOffer,
    this.membershipAdded = false,
  });

  String _membershipSubtitle(Map<String, dynamic> config) {
    final subtitle = config['subtitle'] as String? ?? "D2D Prime Membership";
    final price = (config['price'] as num?)?.toDouble();
    if (price == null) return subtitle;
    return "$subtitle · ₹${price.toStringAsFixed(0)}";
  }

  @override
  Widget build(BuildContext context) {
    Widget buildRow(
      String title,
      String subtitle, {
      bool isArrow = false,
      bool isBuyButton = false,
      String buyButtonText = "Add To Cart",
      bool buyButtonDisabled = false,
      bool isRemoveButton = false,
      VoidCallback? onPressed,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            /// 👉 Arrow (Apply Coupon)
            if (isArrow)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CouponScreen(),
                    ),
                  );
                  if (onApply != null) onApply!();
                },
                child: const Icon(
                  Icons.chevron_right,
                  color: AppColors.white,
                  size: 24,
                ),
              ),

            /// 👉 Buy Button
            if (isBuyButton)
              ElevatedButton(
                onPressed: buyButtonDisabled ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRemoveButton
                      ? Colors.redAccent
                      : (buyButtonDisabled
                          ? AppColors.border
                          : AppColors.white),
                  foregroundColor: isRemoveButton
                      ? Colors.white
                      : (buyButtonDisabled ? AppColors.grey : Colors.black),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  buyButtonText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final config = membershipOffer;
    final showMembership = config != null &&
        config.isNotEmpty &&
        config['active'] != false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          buildRow(
            "Apply Coupon",
            "Use a coupon code for your cart",
            isArrow: true,
            onPressed: onApply,
          ),

          if (totalDiscount > 0) ...[
            const Divider(color: AppColors.divider),
            buildRow(
              "₹${totalDiscount.toStringAsFixed(0)} saved",
              "Discount applied on your order",
            ),
          ],

          if (deliveryCharge == 0) ...[
            const Divider(color: AppColors.divider),
            buildRow(
              "Free Delivery",
              "No delivery charges on this order",
            ),
          ],

          if (showMembership) ...[
            const Divider(color: AppColors.divider),
            buildRow(
              config['title'] as String? ?? "Unlimited Free Deliveries",
              _membershipSubtitle(config),
              isBuyButton: true,
              isRemoveButton: membershipAdded,
              buyButtonText: membershipAdded
                  ? "Remove"
                  : (config['buttonText'] as String? ?? "Add To Cart"),
              buyButtonDisabled: false,
              onPressed: membershipAdded ? onRemove : onBuy,
            ),
          ],
        ],
      ),
    );
  }
}

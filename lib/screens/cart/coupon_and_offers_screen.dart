import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'coupon_screen.dart';

class CouponAndOffersCard extends StatelessWidget {
  final VoidCallback? onApply;
  final VoidCallback? onBuy;

  const CouponAndOffersCard({super.key, this.onApply, this.onBuy});

  @override
  Widget build(BuildContext context) {
    Widget buildRow(
      String title,
      String subtitle, {
      bool isArrow = false,
      bool isBuyButton = false,
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
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Add To Cart",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      );
    }

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

          const Divider(color: AppColors.divider),

          buildRow(
            "₹121 saved",
            "Items at ₹99 applied",
          ),

          const Divider(color: AppColors.divider),

          buildRow(
            "₹45 saved",
            "Delivery applied",
          ),

          const Divider(color: AppColors.divider),

          buildRow(
            "Unlimited Free Deliveries",
            "D2D Prime Membership",
            isBuyButton: true,
            onPressed: onBuy,
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'coupon_screen.dart';
class CouponAndOffersCard extends StatelessWidget {
  final VoidCallback? onApply;
  final VoidCallback? onBuy;

  const CouponAndOffersCard({super.key, this.onApply, this.onBuy});
  void onprssedApplyCoupon(){
    
  }
  @override
  Widget build(BuildContext context) {
    final Color brandColor = Colors.deepOrange;

    Widget buildRow(String title, String subtitle,
        {bool isButton = false, bool isBuyButton = false, VoidCallback? onPressed}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            if (isButton)
          GestureDetector(
          onTap: () {
            // Navigate to CouponScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CouponScreen(),
              ),
            );
          },
          child: Icon(
            Icons.chevron_right,
            color: brandColor,
            size: 30,
          ),
        ),
            if (isBuyButton)
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Add To Cart",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          buildRow("Apply Coupon", "Use a coupon code for your cart",
              isButton: true, onPressed: onApply),
          const Divider(height: 1, color: Colors.grey),
          buildRow("₹121 saved", "Items at ₹99 applied"),
          const Divider(height: 1, color: Colors.grey),
          buildRow("₹45 saved", "Delivery Applied"),
          const Divider(height: 1, color: Colors.grey),
          buildRow("Unlimited Free Deliveries", "D2D Prime Membership",
              isBuyButton: true, onPressed: onBuy),
        ],
      ),
    );
  }
}

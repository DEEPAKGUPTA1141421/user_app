import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class DeliveryInfo extends StatelessWidget {
  const DeliveryInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final mutedColor = Colors.grey.shade500;
    final secondaryColor = Colors.grey.shade200;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16), // match ProductDetailsGrid
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Delivery details",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // HOME Address
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.home, size: 20, color: mutedColor),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("HOME",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text(
                          "403, Zolo Darren, 153 50, Maru...",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                Icon(CupertinoIcons.chevron_right, size: 20, color: mutedColor),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Delivery Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.local_shipping, size: 20, color: mutedColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Delivery by 12 Oct, Sun",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: const [
                            Text("🎆", style: TextStyle(fontSize: 20)),
                            SizedBox(width: 4),
                            Text("🎇", style: TextStyle(fontSize: 20)),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Text(
                          "Arriving Before Diwali",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        SizedBox(width: 4),
                        Text("🎁📦"),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Fulfilled by Seller
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(CupertinoIcons.building_2_fill, size: 20, color: mutedColor),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Fulfilled by DreamBeautyFashion",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "4.1★ • 10 years with Flipkart",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

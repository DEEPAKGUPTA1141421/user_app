import 'package:flutter/material.dart';

class CustomerSupportPage extends StatelessWidget {
  static const brandColor = Color(0xFFFF5200); // Flipkart blue

  final List<Map<String, String>> recentOrders = const [
    {
      "id": "1",
      "name": "Chilli Green",
      "image": "🌶️",
      "date": "Jan 04",
      "status": "delivered"
    },
    {
      "id": "2",
      "name": "FORTUNE Everyday Basmati Ric...",
      "image": "🍚",
      "date": "Jan 04",
      "status": "delivered"
    },
    {
      "id": "3",
      "name": "Onion",
      "image": "🧅",
      "date": "Oct 20, 2024",
      "status": "delivered"
    },
  ];

  const CustomerSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "24x7 Customer Support",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: brandColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          children: [
            // GST Banner
            Container(
              color: brandColor.withOpacity(0.1),
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                        child: Text("₹", style: TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("GST Rate Updates",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text(
                          "Quick answers to all your queries",
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text("Know more ›",
                              style: TextStyle(color: brandColor)),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),

            // Recent Orders
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      "Select the order to track and manage it conveniently",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Column(
                    children: recentOrders.map((order) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                              context, "/account/orders/${order['id']}");
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(order["image"]!,
                                      style: const TextStyle(fontSize: 24)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(order["name"]!,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Delivered on ${order["date"]}",
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: Colors.grey)
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text("View more ›",
                        style: TextStyle(color: brandColor)),
                  )
                ],
              ),
            ),

            // Travel Bookings
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, "/account/travel");
                },
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: brandColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flight,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Text("Travel Bookings")),
                    const Icon(Icons.chevron_right, color: Colors.grey)
                  ],
                ),
              ),
            ),

            // Help Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("What issue are you facing?",
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 12),
                  GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      buildHelpButton("📦", "Track Order"),
                      buildHelpButton("🔄", "Return/Refund"),
                      buildHelpButton("❌", "Cancel Order"),
                      buildHelpButton("💬", "Other Issues"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Chat Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: brandColor,
        onPressed: () {},
        child: const Text("😊", style: TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget buildHelpButton(String emoji, String text) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(text,
              style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }
}

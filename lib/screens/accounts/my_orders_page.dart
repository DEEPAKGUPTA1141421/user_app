import 'package:flutter/material.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  final List<Map<String, dynamic>> orders = [
    {
      "id": "1",
      "items": ["🌶️", "🥬"],
      "name": "Chilli Green",
      "date": "Jan 04",
      "status": "delivered",
      "count": 2
    },
    {
      "id": "2",
      "items": ["🍚"],
      "name": "FORTUNE Everyday Basmati Ric...",
      "date": "Jan 04",
      "status": "delivered",
      "count": 2
    },
    {
      "id": "3",
      "items": ["🧅"],
      "name": "Onion",
      "date": "Oct 20, 2024",
      "status": "delivered",
      "count": 1
    },
    {
      "id": "4",
      "items": ["🥔", "🍌"],
      "name": "Minutes Basket",
      "date": "Oct 14",
      "status": "delivered",
      "count": 2
    },
    {
      "id": "5",
      "items": ["🍟", "🍟"],
      "name": "Minutes Basket",
      "date": "Oct 06",
      "status": "delivered",
      "count": 2
    },
  ];

  @override
  Widget build(BuildContext context) {
    final brandColor = Color(0xFFFF5200);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Travel Bookings Button
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              onPressed: () {
                Navigator.pushNamed(context, "/travel-bookings");
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Travel bookings",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text("↗", style: TextStyle(color: brandColor, fontSize: 18)),
                ],
              ),
            ),
          ),

          // Promotional Banner
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pinkAccent, Colors.pink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Extra ₹1,000 discount* on\nSamsung appliances",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Flipkart Axis Bank Credit Card ›",
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Text("📱", style: TextStyle(fontSize: 40)),
              ],
            ),
          ),

          // Search and Filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search your order here",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      side: const BorderSide(color: Colors.grey)),
                  onPressed: () {},
                  child: const Icon(Icons.filter_list, color: Colors.black),
                ),
              ],
            ),
          ),

          // Orders List
          Container(
            color: Colors.white,
            child: Column(
              children: orders.map((order) {
                return InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, "/order/${order['id']}");
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children:
                              (order['items'] as List<String>).map((item) {
                            return Container(
                              width: 50,
                              height: 50,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(item,
                                  style: const TextStyle(fontSize: 22)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(width: 10),

                        // Order Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Delivered on ${order['date']}",
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${order['name']} (${order['count']} item${order['count'] > 1 ? 's' : ''})",
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),

                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

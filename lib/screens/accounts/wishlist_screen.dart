import 'package:flutter/material.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  String activeTab = "my";

  final List<Map<String, dynamic>> wishlistItems = [
    {
      "id": 1,
      "name": "RedmiBook Pro Core i5 11...",
      "image": "💻",
      "price": "₹39,699",
      "originalPrice": "₹59,999",
      "discount": "33%",
      "rating": 4.5,
      "available": false,
    },
    {
      "id": 2,
      "name": "SILVER SHINE Party We...",
      "image": "👂",
      "price": "",
      "originalPrice": "",
      "discount": "",
      "rating": 0.0,
      "available": false,
    },
  ];

  final List<Map<String, dynamic>> collections = [
    {"image": "💻", "id": 1},
    {"image": "👂", "id": 2},
    {"image": "", "id": 3},
    {"image": "", "id": 4},
  ];

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFFF5200);
    const secondaryColor = Color(0xFFF5F5F5);
    const cardColor = Colors.white;
    const mutedColor = Colors.grey;

    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        title: const Text("Wishlist & Collections"),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: cardColor,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => activeTab = "my"),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            "My collections",
                            style: TextStyle(
                              color:
                                  activeTab == "my" ? brandColor : mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (activeTab == "my")
                          Container(
                            height: 2,
                            color: brandColor,
                          )
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => activeTab = "follow"),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            "Collections I follow",
                            style: TextStyle(
                              color: activeTab == "follow"
                                  ? brandColor
                                  : mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (activeTab == "follow")
                          Container(
                            height: 2,
                            color: brandColor,
                          )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: activeTab == "my"
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        // Collection Preview
                        Container(
                          color: cardColor,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GridView.builder(
                                itemCount: collections.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemBuilder: (context, index) {
                                  final item = collections[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: secondaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Center(
                                      child: Text(
                                        item["image"] ?? "",
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "My Wishlist",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: const [
                                  Text("🔒 Private • 2 items",
                                      style: TextStyle(
                                          fontSize: 13, color: mutedColor)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Wishlist Items
                        Container(
                          color: cardColor,
                          padding: const EdgeInsets.all(16),
                          child: GridView.builder(
                            itemCount: wishlistItems.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.7,
                            ),
                            itemBuilder: (context, index) {
                              final item = wishlistItems[index];
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: Icon(Icons.more_vert,
                                          color: Colors.grey[600], size: 18),
                                    ),
                                    Container(
                                      height: 90,
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: secondaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          item["image"],
                                          style: const TextStyle(fontSize: 36),
                                        ),
                                      ),
                                    ),
                                    if (!item["available"])
                                      const Text(
                                        "Currently unavailable",
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    Text(
                                      item["name"],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    if (item["price"] != "")
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                "↓ ${item["discount"]}",
                                                style: const TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                item["originalPrice"],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: mutedColor,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            item["price"],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Row(
                                            children: List.generate(5, (i) {
                                              return Icon(
                                                Icons.star,
                                                size: 12,
                                                color: i <
                                                        (item["rating"]
                                                                as double)
                                                            .floor()
                                                    ? Colors.green
                                                    : Colors.grey[400],
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                    const Spacer(),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: brandColor,
                                        side: BorderSide(color: brandColor),
                                        backgroundColor: Colors.white,
                                      ),
                                      onPressed: () {},
                                      child: const Text("Add to Cart"),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // Create New Collection
                        Container(
                          color: cardColor,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(16),
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: brandColor),
                              foregroundColor: brandColor,
                            ),
                            label: const Text("Create a new collection"),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "No collections followed yet",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

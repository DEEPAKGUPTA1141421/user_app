import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool showDiscount;

  const ProductCard({
    super.key,
    required this.product,
    this.showDiscount = true,
  });

  @override
  Widget build(BuildContext context) {
    final title = product['name'] ?? 'Product name';
    final description = product['description'] ?? 'Description:';
    final imageUrl = product['imageUrl'] ??
        'https://i.pinimg.com/736x/61/ee/97/61ee975bfcaa7c5b5c91226a623c1ed8.jpg';

    return Card(
      color: Colors.transparent, // make card background transparent
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 100, // fixed width
        height: 160, // fixed height
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              // 🔶 Title with orange background, centered
              Container(
                width: double.infinity, // take full card width
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center, // center horizontally
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // contrast with orange background
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              // 📝 Description centered
              Expanded(
                // 👈 prevent overflow
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class Product {
  final int id;
  final String image;
  final double rating;
  final String name;
  final String description;
  final double originalPrice;
  final double salePrice;
  final int discount;

  Product({
    required this.id,
    required this.image,
    required this.rating,
    required this.name,
    required this.description,
    required this.originalPrice,
    required this.salePrice,
    required this.discount,
  });
}

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final successColor = Colors.green;
    final mutedColor = Colors.grey.shade500;
    final primaryColor = Colors.blue; // replace with your theme primary

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 1.05),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image + Rating Badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.product.image,
                      width: 160,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Text(
                            widget.product.rating.toString(),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          Icon(CupertinoIcons.star_fill,
                              size: 12, color: successColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Name
              Text(
                widget.product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 2),

              // Description
              Text(
                widget.product.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: mutedColor),
              ),
              const SizedBox(height: 4),

              // Discount
              Row(
                children: [
                  Text(
                    "${widget.product.discount}% OFF",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: successColor),
                  ),
                ],
              ),
              const SizedBox(height: 2),

              // Prices
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "₹${widget.product.originalPrice.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: mutedColor,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "₹${widget.product.salePrice.toStringAsFixed(0)}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: primaryColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Top Discount of the Sale",
                  style: TextStyle(fontSize: 10, color: primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

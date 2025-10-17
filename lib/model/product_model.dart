// lib/models/product_model.dart
class Product {
  final String id;
  final String name;
  final String? imageUrl;
  final double price;
  final double? discountPrice;

  Product({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.price,
    this.discountPrice,
  });
}

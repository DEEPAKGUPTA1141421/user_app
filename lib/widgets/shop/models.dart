class Product {
  final String id;
  final String name;
  final String image;
  final double price;
  final double? originalPrice;
  final double rating;
  final int ratingCount;
  final String? badge;

  const Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.ratingCount,
    this.badge,
  });

  int? get discountPercent {
    if (originalPrice == null) return null;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }
}

class ProductCategory {
  final String name;
  final List<Product> products;

  const ProductCategory({required this.name, required this.products});
}

class Review {
  final String id;
  final String userName;
  final String avatar;
  final double rating;
  final String date;
  final String title;
  final String body;
  final int helpfulCount;
  final bool verified;

  const Review({
    required this.id,
    required this.userName,
    required this.avatar,
    required this.rating,
    required this.date,
    required this.title,
    required this.body,
    required this.helpfulCount,
    required this.verified,
  });
}

class Shop {
  final String id;
  final String name;
  final String image;
  final String bannerImage;
  final double rating;
  final int ratingCount;
  final String category;
  final String deliveryTime;
  final String distance;
  final String? offer;
  final String description;
  final List<String> tags;
  final List<ProductCategory> productCategories;
  final List<Review> reviews;

  const Shop({
    required this.id,
    required this.name,
    required this.image,
    required this.bannerImage,
    required this.rating,
    required this.ratingCount,
    required this.category,
    required this.deliveryTime,
    required this.distance,
    this.offer,
    required this.description,
    required this.tags,
    required this.productCategories,
    required this.reviews,
  });
}

class FilterOptions {
  final List<String> distance;
  final List<String> brands;
  final List<String> categories;
  final List<String> rating;
  final List<String> deliveryOptions;
  final List<String> offers;

  const FilterOptions({
    this.distance = const [],
    this.brands = const [],
    this.categories = const [],
    this.rating = const [],
    this.deliveryOptions = const [],
    this.offers = const [],
  });

  FilterOptions copyWith({
    List<String>? distance,
    List<String>? brands,
    List<String>? categories,
    List<String>? rating,
    List<String>? deliveryOptions,
    List<String>? offers,
  }) {
    return FilterOptions(
      distance: distance ?? this.distance,
      brands: brands ?? this.brands,
      categories: categories ?? this.categories,
      rating: rating ?? this.rating,
      deliveryOptions: deliveryOptions ?? this.deliveryOptions,
      offers: offers ?? this.offers,
    );
  }

  int get totalSelected =>
      distance.length +
      brands.length +
      categories.length +
      rating.length +
      deliveryOptions.length +
      offers.length;

  FilterOptions get empty => const FilterOptions();
}
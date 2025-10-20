class Product {
  final int id;
  final String name;
  final String image;
  final double originalPrice;
  final double salePrice;
  final int discount;
  final double rating;
  final String deliveryDate;
  final bool? isBestseller;
  final bool? isTopDiscount;
  final bool? hasComboOffer;
  final double? comboSavings;
  final bool? isExpressDelivery;
  final bool? isSponsored;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.originalPrice,
    required this.salePrice,
    required this.discount,
    required this.rating,
    required this.deliveryDate,
    this.isBestseller,
    this.isTopDiscount,
    this.hasComboOffer,
    this.comboSavings,
    this.isExpressDelivery,
    this.isSponsored,
  });
}

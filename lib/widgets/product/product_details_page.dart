import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/product_provider.dart';
import '../../provider/cart_provider.dart';
import '../../widgets/real_search_page.dart';
import 'product_image_carousel.dart';
import 'delivery_info.dart';
import 'service_features.dart';
import 'best_review.dart';
import 'package:shimmer/shimmer.dart';

class ProductDetailsPage extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailsPage({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends ConsumerState<ProductDetailsPage> {
  bool _argsLoaded = false;
  late String itemType;
  late String title;
  late String imageUrl;
  late String itemId;

  @override
  void initState() {
    super.initState();
    print("Fetching product details for id: ${widget.productId}");
    Future.microtask(() {
      ref.read(productPod.notifier).fetchProductDetail(widget.productId);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        itemType = args['itemType'] ?? "Product";
        title = args['title'] ?? "Unnamed Product";
        imageUrl = args['imageUrl'] ?? "https://via.placeholder.com/150";
        itemId = args['itemId'] ?? "";
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(productPod.notifier)
              .saveSearch(itemId, itemType, title, imageUrl);
        });
      }
      _argsLoaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productPod);
    final bool isLoading = productState['isLoading'] ?? false;
    final productDetail = productState['product_detail'];
    const brandColor = Color(0xFFFF5200);
    final cartState = ref.watch(cartProvider); // Access cart data
    final cartItems = cartState['cartData']['items'] ?? [];
// ✅ Extract product images where is_image_attribute == true
    final imageAttributes =
        (productDetail['product_attributes'] as List?)?.where((attr) {
      return attr['is_image_attribute'] == true;
    }).toList();

    List<String> imageUrls = [];
    List<String> imageColors = [];

    if (imageAttributes != null && imageAttributes.isNotEmpty) {
      final attr =
          imageAttributes.first; // there’s usually only one such attribute

      final List<dynamic>? images = attr['images'];
      final List<dynamic>? values = attr['values'];

      if (images != null && images.isNotEmpty) {
        imageUrls = images.map((e) => e.toString()).toList();
      }

      if (values != null && values.isNotEmpty) {
        imageColors = values.map((e) => e.toString()).toList();
      }

      print("🖼️ Extracted Images: $imageUrls");
      print("🎨 Color Names: $imageColors");
    }
    // ✅ Extract product basic details
    print("Image Attributes: $imageUrls");
    final name = productDetail['name'] ?? 'Unnamed Product';
    final description = productDetail['description'] ?? '';
    final stock = productDetail['stock'] ?? 0;
    // Check if the current product is already in the cart
    final isInCart = cartItems.any((item) => item['productId'] == widget.productId);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          readOnly: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RealSearchPage()),
          ),
          decoration: InputDecoration(
            hintText: "Search for products",
            filled: true,
            fillColor: Colors.grey[200],
            prefixIcon: const Icon(CupertinoIcons.search, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      body: isLoading
          ? _buildShimmer()
          : productDetail == null
              ? const Center(child: Text("No product found"))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProductImageCarousel(
                        imageUrls: imageUrls,
                        productDetails: {
                          "Fabric": "Cotton",
                          "Neck": "Round Neck",
                        },
                        rating: 4.2,
                        ratingCount: "12.5K+",
                      ),

                      // 🔹 Dynamic Product Attributes
                      _buildProductAttributes(
                        productDetail['product_attributes'] ?? [],
                        isLoading,
                      ),

                      const SizedBox(height: 16),

                      const DeliveryInfo(),
                      const ServiceFeatures(),

                      // 🔹 Reviews
                      const SizedBox(height: 12),
                      BestReview(
                        reviews: const [
                          {
                            "rating": 5,
                            "title": "Great product!",
                            "comment": "Loved the quality!",
                            "author": "User, Delhi",
                            "date": "Oct 2025",
                            "verified": true
                          }
                        ],
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),

      // 🔹 Bottom Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: CupertinoColors.systemGrey)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: brandColor),
                  foregroundColor: brandColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  isInCart ? "Added to Cart" : "Add to Cart",
                  style: TextStyle(
                    color: isInCart ? Colors.green : brandColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Buy Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔸 Shimmer placeholder when product is loading
  Widget _buildShimmer() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          margin: const EdgeInsets.all(12),
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// 🔹 Render product attributes dynamically
  Widget _buildProductAttributes(List attributes, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: attributes.map((attr) {
          final bool isImage = attr['is_image_attribute'] ?? false;
          final bool isVariant = attr['is_variant_attribute'] ?? false;
          final List values = attr['values'] ?? [];
          final List images = attr['images'] ?? [];

          if (isImage && values.isNotEmpty) {
            // 🔹 Render image options
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Color Options",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 70,
                  child: isLoading
                      ? _buildImageShimmer()
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: values.length,
                          itemBuilder: (context, index) {
                            final imgList = (images.isNotEmpty)
                                ? images[index]
                                    .toString()
                                    .split(',')
                                    .map((e) => e.trim())
                                    .toList()
                                : [];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6.0),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      imgList.isNotEmpty
                                          ? imgList.first
                                          : "https://via.placeholder.com/50",
                                    ),
                                    radius: 25,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(values[index],
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
              ],
            );
          } else if (isVariant) {
            // 🔹 Render variant (e.g. size)
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Variants",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: values.map<Widget>((v) {
                    return isLoading
                        ? _buildBoxShimmer()
                        : Chip(
                            label: Text(v),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: const BorderSide(color: Colors.grey),
                            ),
                          );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            );
          } else {
            // 🔹 Normal text attribute
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                "${values.join(', ')}",
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
            );
          }
        }).toList(),
      ),
    );
  }

  /// 🔸 Shimmer for image options
  Widget _buildImageShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: 60,
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  /// 🔸 Shimmer for variant boxes
  Widget _buildBoxShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

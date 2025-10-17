import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'product_highlights.dart';

class ProductImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final Map<String, String>? productDetails; // optional
  final double? rating; // product rating
  final String? ratingCount; // rating count like "13.7K+"

  const ProductImageCarousel({
    super.key,
    required this.imageUrls,
    this.productDetails,
    this.rating,
    this.ratingCount,
  });

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  final PageController _controller = PageController();
  void shareContent() async {}

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 380,
      width: double.infinity,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          bool showDetails = widget.productDetails != null && index == 1;

          return Stack(
            fit: StackFit.expand,
            children: [
              /// Product image
              Image.network(
                widget.imageUrls[index],
                fit: BoxFit.cover,
              ),

              /// Semi-transparent detail overlay (for specific image)
              if (showDetails)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  padding: const EdgeInsets.all(16),
                  child: const ProductHighlights(
                    highlights: {
                      "Top Type": "Regular Top",
                      "Sleeve Style": "Bishop Sleeve",
                      "Neck": "Square Neck",
                      "Fabric": "Polyester",
                      "Pattern": "Solid",
                    },
                  ),
// provide empty map if null
                ),

              /// Rating Badge (top-left)
              if (widget.rating != null && widget.ratingCount != null)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star,
                            color: Colors.greenAccent, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "${widget.rating} | ${widget.ratingCount}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              /// Top-right icons (wishlist & share)
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  children: [
                    // Wishlist icon
                    Container(
                      margin: const EdgeInsets.only(
                          bottom: 8), // spacing between icons
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),

                    // Share icon
                    GestureDetector(
                      onTap: () async {
                        shareContent();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.share,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

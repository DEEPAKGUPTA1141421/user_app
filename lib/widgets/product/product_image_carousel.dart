import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'product_highlights.dart';

class ProductImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final Map<String, String>? productDetails;
  final double? rating;
  final String? ratingCount;
  final bool isInWishlist;
  final bool isTogglingWishlist;
  final VoidCallback? onWishlist;
  final VoidCallback? onShare;

  const ProductImageCarousel({
    super.key,
    required this.imageUrls,
    this.productDetails,
    this.rating,
    this.ratingCount,
    this.isInWishlist = false,
    this.isTogglingWishlist = false,
    this.onWishlist,
    this.onShare,
  });

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  final PageController _controller = PageController();

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
                    GestureDetector(
                      onTap: widget.onWishlist,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: widget.isTogglingWishlist
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black),
                              )
                            : Icon(
                                widget.isInWishlist
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: widget.isInWishlist
                                    ? Colors.red
                                    : Colors.black,
                                size: 20,
                              ),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onShare,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.ios_share_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
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

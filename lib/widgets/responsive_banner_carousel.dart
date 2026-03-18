import 'package:flutter/material.dart';

class ResponsiveBannerCarousel extends StatefulWidget {
  final List<dynamic> banners;
  final String categoryId;

  const ResponsiveBannerCarousel({
    super.key,
    required this.banners,
    required this.categoryId,
  });

  @override
  State<ResponsiveBannerCarousel> createState() => _ResponsiveBannerCarouselState();
}

class _ResponsiveBannerCarouselState extends State<ResponsiveBannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: _getViewportFraction(context),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double _getViewportFraction(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Phone: full width (1.0), Tablet/Desktop: partial (0.85)
    return screenWidth < 600 ? 1.0 : 0.85;
  }

  void _handleBannerTap(Map<String, dynamic> banner) {
    final redirectType = banner['redirectType'] ?? '';
    final redirectRefId = banner['redirectRefId'] ?? '';

    // Handle redirects based on type
    if (redirectType == 'PRODUCT') {
      // Navigate to product detail
      print('Navigate to product: $redirectRefId');
    } else if (redirectType == 'CATEGORY') {
      // Navigate to category
      print('Navigate to category: $redirectRefId');
    } else if (redirectType == 'MARKETING') {
      // Open marketing URL or page
      print('Open marketing: $redirectRefId');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              final mediaType = banner['mediaType'] ?? 'IMAGE';
              final mediaUrl = banner['mediaUrl'] ?? '';
              final title = banner['title'] ?? '';
              final logoUrl = banner['logoUrl'] ?? '';

              return GestureDetector(
                onTap: () => _handleBannerTap(banner),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image or video thumbnail
                      if (mediaType == 'IMAGE')
                        Image.network(
                          mediaUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.image_not_supported, size: 48),
                              ),
                            );
                          },
                        )
                      else if (mediaType == 'VIDEO')
                        Container(
                          color: Colors.black87,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Video thumbnail or placeholder
                              mediaUrl.isNotEmpty
                                  ? Image.network(
                                      mediaUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade800,
                                        );
                                      },
                                    )
                                  : Container(color: Colors.grey.shade800),
                              // Play button overlay
                              const Center(
                                child: Icon(
                                  Icons.play_circle_outline,
                                  size: 64,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Banner content overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.black.withOpacity(0.2),
                            ],
                          ),
                        ),
                      ),

                      // Logo and Title
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (logoUrl.isNotEmpty)
                              Image.network(
                                logoUrl,
                                height: 40,
                                width: 40,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox(
                                    height: 40,
                                    width: 40,
                                  );
                                },
                              ),
                            const Spacer(),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              );
            },
          ),
        ),
        // Indicator dots
        if (widget.banners.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.banners.length,
                (index) => Container(
                  width: _currentPage == index ? 28 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == index
                        ? const Color(0xFF7500DB)
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';

class BannerSlide {
  final int id;
  final String title;
  final String subtitle;
  final String price;
  final String? originalPrice;
  final String image;
  final String? badge;
  final Gradient bgGradient;

  BannerSlide({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    this.originalPrice,
    required this.image,
    this.badge,
    required this.bgGradient,
  });
}

// Example slides
final List<BannerSlide> bannerSlides = [
  BannerSlide(
    id: 1,
    title: "vivo T4 Lite 5G",
    subtitle: "Next-Gen Performance",
    price: "₹8,999*",
    originalPrice: "₹12,999",
    image:
        "https://i.pinimg.com/736x/de/77/de/de77deab31779bc4ed3fae38062fc27f.jpg",
    badge: "THE BIG BILLION DAYS",
    bgGradient: LinearGradient(colors: [Colors.purple, Colors.orange]),
  ),
  BannerSlide(
    id: 2,
    title: "iPhone 15 Pro",
    subtitle: "Titanium. So Pro.",
    price: "₹1,34,900*",
    originalPrice: "₹1,49,900",
    image:
        "assets/phone-2.pnghttps://i.pinimg.com/736x/de/77/de/de77deab31779bc4ed3fae38062fc27f.jpg",
    badge: "MEGA SALE",
    bgGradient: LinearGradient(colors: [Colors.blue, Colors.pink]),
  ),
  BannerSlide(
    id: 3,
    title: "Galaxy S24 Ultra",
    subtitle: "Galaxy AI is Here",
    price: "₹1,29,999*",
    originalPrice: "₹1,49,999",
    image:
        "https://i.pinimg.com/736x/de/77/de/de77deab31779bc4ed3fae38062fc27f.jpg",
    badge: "LIMITED TIME",
    bgGradient: LinearGradient(colors: [Colors.green, Colors.teal]),
  ),
];

class BannerSection extends StatefulWidget {
  final List<dynamic> section;
  const BannerSection({super.key, required this.section});

  @override
  State<BannerSection> createState() => _AutoScrollBannerState();
}

class _AutoScrollBannerState extends State<BannerSection> {
  final PageController _controller = PageController();
  int currentSlide = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      setState(() {
        currentSlide = (currentSlide + 1) % bannerSlides.length;
      });
      _controller.animateToPage(
        currentSlide,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200, // max height
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: bannerSlides.length,
            onPageChanged: (index) => setState(() => currentSlide = index),
            itemBuilder: (context, index) {
              final slide = bannerSlides[index];
              return Container(
                decoration: BoxDecoration(
                  gradient: slide.bgGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Left Content
                    Flexible(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (slide.badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                slide.badge!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            slide.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            slide.subtitle,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                slide.price,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (slide.originalPrice != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  slide.originalPrice!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                )
                              ]
                            ],
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            onPressed: () {},
                            child: const Text(
                              "Buy Now",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    ),
                    // Right Image
                    Flexible(
                      flex: 1,
                      child: Center(
                        child: SizedBox(
                          width: 120,
                          height: 180,
                          child: Transform.rotate(
                            angle: 45 *
                                3.1415927 /
                                180, // convert 45 degrees to radians
                            child: Image.network(
                              slide.image,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                    child: CircularProgressIndicator(
                                  color: Colors.white,
                                ));
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image,
                                      color: Colors.white, size: 32),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Slide Indicators
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                bannerSlides.length,
                (index) => GestureDetector(
                  onTap: () {
                    setState(() => currentSlide = index);
                    _controller.animateToPage(index,
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeInOut);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: currentSlide == index ? 40 : 30,
                    height: currentSlide == index ? 10 : 6,
                    decoration: BoxDecoration(
                      color: currentSlide == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      shape: BoxShape.rectangle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Progress Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: (currentSlide + 1) / bannerSlides.length,
              color: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.2),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}

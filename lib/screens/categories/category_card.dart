import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final String image;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.title,
    required this.image,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔥 Premium circular container (Flipkart/Amazon style)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface2,
              border: Border.all(color: AppColors.border),
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.network(
                  image, // ✅ uses imageUrl directly
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.grey,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // 🔥 Text styling (consistent typography)
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
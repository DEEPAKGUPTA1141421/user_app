import 'package:flutter/material.dart';
import 'package:user_app/utils/app_colors.dart';

/// Network image with graceful loading and error states.
///
/// Uses [Image.network] with a shimmer-style placeholder and error fallback.
/// Replace with `cached_network_image` package for disk caching when needed.
class CachedProductImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CachedProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    Widget image;

    if (url == null || url.isEmpty) {
      image = _placeholder();
    } else {
      image = Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder();
        },
        errorBuilder: (context, _, __) => _errorPlaceholder(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surface2,
    );
  }

  Widget _errorPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surface2,
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined,
            color: AppColors.greyDark, size: 24),
      ),
    );
  }
}

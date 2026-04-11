import 'package:flutter/material.dart';
import 'package:user_app/utils/app_colors.dart';

/// Full-screen loading overlay. Use inside a [Stack] on top of content.
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      ),
    );
  }
}

/// Inline centered loading indicator for use inside scrollable content.
class AppLoader extends StatelessWidget {
  final Color color;

  const AppLoader({super.key, this.color = AppColors.white});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: color),
    );
  }
}

/// Shimmer skeleton block – drop-in replacement for any list/grid placeholder.
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: borderRadius,
      ),
    );
  }
}

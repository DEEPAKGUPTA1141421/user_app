import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

const Color _kBrand = Color(0xFFFF5200);

/// Full-screen dark overlay with a branded pill loader.
/// Drop into a [Stack] above content when [isLoading] is true.
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.55),
      child: const Center(child: _LoaderPill()),
    );
  }
}

/// Inline centered loader — use inside scrollable areas or empty states.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: _LoaderPill());
  }
}

/// The shared pill widget: rounded dark card + brand-orange spinner.
class _LoaderPill extends StatelessWidget {
  const _LoaderPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            color: _kBrand,
            strokeWidth: 2.5,
            strokeCap: StrokeCap.round,
          ),
        ),
      ),
    );
  }
}

/// Consistent [RefreshIndicator] style for all screens.
/// Wrap any scrollable child with this for pull-to-refresh.
class AppRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _kBrand,
      backgroundColor: AppColors.surface,
      strokeWidth: 2.5,
      child: child,
    );
  }
}

/// Shimmer skeleton block — placeholder for list/grid items.
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

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// Deep-white modern spinner. Use everywhere instead of [CircularProgressIndicator].
///
/// [color] defaults to white. For spinners inside light/white buttons pass
/// the button's foreground color (e.g. [AppColors.bg]).
class AppSpinner extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const AppSpinner({
    super.key,
    this.size = 22,
    this.color = Colors.white,
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: color,
        backgroundColor: color.withOpacity(0.12),
        strokeWidth: strokeWidth,
        strokeCap: StrokeCap.round,
      ),
    );
  }
}

/// Full-screen dark overlay with a pill loader.
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

/// Rounded card containing the white spinner.
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
        child: AppSpinner(size: 26),
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
      color: Colors.white,
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

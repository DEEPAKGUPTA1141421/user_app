import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// Empty / error state widget for shop product lists.
///
/// Shows an icon, a message, and an optional action button.
/// Used for: empty search results, no products in shop, network errors.
class ShopProductEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  /// Label for the optional action button (e.g. "Retry", "Clear search").
  final String? actionLabel;
  final VoidCallback? onAction;

  const ShopProductEmptyState({
    super.key,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.greyDark, size: 44),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../model/section_v2.dart';
import '../../utils/app_colors.dart';

// Shared wrapper: title header + background + bottom spacing for all section widgets.
class SectionShell extends StatelessWidget {
  final SectionV2 section;
  final Widget child;
  final bool showTitle;

  const SectionShell({
    super.key,
    required this.section,
    required this.child,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = section.theme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: theme.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle && section.title.isNotEmpty)
            _SectionHeader(title: section.title, paddingX: theme.paddingX, paddingY: theme.paddingY),
          child,
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final double paddingX;
  final double paddingY;

  const _SectionHeader({
    required this.title,
    required this.paddingX,
    required this.paddingY,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(paddingX, paddingY, paddingX, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.grey,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

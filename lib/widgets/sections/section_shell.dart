import 'package:flutter/material.dart';
import '../../model/section_v2.dart';

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
            _SectionHeader(title: section.title, theme: theme),
          child,
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final SectionTheme theme;
  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          theme.paddingX, theme.paddingY, theme.paddingX, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: theme.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.fg),
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 13, color: theme.accent),
        ],
      ),
    );
  }
}

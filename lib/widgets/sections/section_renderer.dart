import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../model/section_v2.dart';
import 'widget_registry.dart';

/// Routes a SectionV2 to the correct layout widget via widgetRegistry.
class SectionRenderer extends StatelessWidget {
  final SectionV2 section;
  final OnNavigate? onNavigate;

  const SectionRenderer({
    super.key,
    required this.section,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    if (!section.active || section.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final builder = widgetRegistry[section.widgetKey];

    if (builder == null) {
      if (kDebugMode) {
        debugPrint(
            '[SectionRenderer] unknown widgetKey="${section.widgetKey}" — skipping');
      }
      return const SizedBox.shrink();
    }

    return builder(section, onNavigate);
  }
}

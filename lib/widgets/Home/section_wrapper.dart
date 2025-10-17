import 'package:flutter/material.dart';

/// ----------------------
/// Section Wrapper
/// ----------------------
class SectionWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final SectionVariant variant;
  final bool hasArrow;
  final EdgeInsetsGeometry? padding;

  const SectionWrapper({
    super.key,
    required this.title,
    required this.child,
    this.variant = SectionVariant.defaultVariant,
    this.hasArrow = true,
    this.padding,
  });

  Color getBackgroundColor(BuildContext context) {
    switch (variant) {
      case SectionVariant.primary:
        return Colors.deepPurple; // or use your gradient
      case SectionVariant.secondary:
        return Colors.teal; // or your gradient
      case SectionVariant.defaultVariant:
      default:
        return Theme.of(context).cardColor;
    }
  }

  Color getTitleColor(BuildContext context) {
    switch (variant) {
      case SectionVariant.primary:
      case SectionVariant.secondary:
        return Colors.white;
      case SectionVariant.defaultVariant:
      default:
        return Theme.of(context).textTheme.bodyText1!.color!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 10),
      decoration: BoxDecoration(
        color: getBackgroundColor(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: getTitleColor(context),
                ),
              ),
              if (hasArrow)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

enum SectionVariant { defaultVariant, primary, secondary }

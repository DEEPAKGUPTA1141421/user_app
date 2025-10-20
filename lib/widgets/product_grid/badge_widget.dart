import 'package:flutter/material.dart';

enum BadgeVariant { 
  defaultVariant, 
  secondary, 
  destructive, 
  outline 
}

class BadgeWidget extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final FontWeight fontWeight;
  final int count;

  const BadgeWidget({
    super.key,
    required this.text,
    this.variant = BadgeVariant.defaultVariant,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.fontSize = 12,
    this.fontWeight = FontWeight.w600,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Define variant styles similar to your React cva setup
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (variant) {
      case BadgeVariant.secondary:
        bgColor = theme.colorScheme.secondary;
        textColor = theme.colorScheme.onSecondary;
        borderColor = Colors.transparent;
        break;
      case BadgeVariant.destructive:
        bgColor = theme.colorScheme.error;
        textColor = theme.colorScheme.onError;
        borderColor = Colors.transparent;
        break;
      case BadgeVariant.outline:
        bgColor = Colors.transparent;
        textColor = theme.colorScheme.onSurface;
        borderColor = theme.dividerColor;
        break;
      case BadgeVariant.defaultVariant:
      default:
        bgColor = theme.colorScheme.primary;
        textColor = theme.colorScheme.onPrimary;
        borderColor = Colors.transparent;
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999), // rounded-full
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: textColor,
        ),
      ),
    );
  }
}

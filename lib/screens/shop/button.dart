import 'package:flutter/material.dart';

enum ButtonVariant {
  defaultVariant,
  destructive,
  outline,
  secondary,
  ghost,
  link
}

enum ButtonSize { defaultSize, sm, lg, icon }

class Button extends StatelessWidget {
  final ButtonVariant variant;
  final ButtonSize size;
  final VoidCallback? onPressed;
  final Widget child;
  final bool asChild;

  const Button({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = ButtonVariant.defaultVariant,
    this.size = ButtonSize.defaultSize,
    this.asChild = false,
  });

  Color getBackgroundColor(BuildContext context) {
    switch (variant) {
      case ButtonVariant.defaultVariant:
        return Colors.blue;
      case ButtonVariant.destructive:
        return Colors.red;
      case ButtonVariant.outline:
        return Colors.transparent;
      case ButtonVariant.secondary:
        return Colors.grey.shade300;
      case ButtonVariant.ghost:
        return Colors.transparent;
      case ButtonVariant.link:
        return Colors.transparent;
    }
  }

  Color getTextColor(BuildContext context) {
    switch (variant) {
      case ButtonVariant.defaultVariant:
      case ButtonVariant.destructive:
        return Colors.white;
      case ButtonVariant.outline:
      case ButtonVariant.secondary:
      case ButtonVariant.ghost:
        return Colors.black;
      case ButtonVariant.link:
        return Colors.blue;
    }
  }

  double getHeight() {
    switch (size) {
      case ButtonSize.defaultSize:
        return 40;
      case ButtonSize.sm:
        return 36;
      case ButtonSize.lg:
        return 44;
      case ButtonSize.icon:
        return 40;
    }
  }

  EdgeInsets getPadding() {
    switch (size) {
      case ButtonSize.defaultSize:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case ButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 10);
      case ButtonSize.icon:
        return EdgeInsets.zero;
    }
  }

  BorderSide? getBorder() {
    if (variant == ButtonVariant.outline) {
      return const BorderSide(color: Colors.black, width: 1);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: getBackgroundColor(context),
        foregroundColor: getTextColor(context),
        padding: getPadding(),
        minimumSize: Size(asChild ? 0 : double.infinity, getHeight()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: getBorder() ?? BorderSide.none,
        ),
        elevation:
            variant == ButtonVariant.ghost || variant == ButtonVariant.link
                ? 0
                : 2,
      ),
      child: child,
    );

    return asChild ? child : button;
  }
}

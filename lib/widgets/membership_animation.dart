import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Shows a brief celebratory / farewell overlay animation for the
/// membership add-on being applied or removed from the cart.
Future<void> showMembershipAnimation(
  BuildContext context, {
  required bool added,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'membership-status',
    barrierColor: Colors.black.withOpacity(0.55),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, __, ___) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: ScaleTransition(
          scale: curved,
          child: _MembershipStatusCard(added: added),
        ),
      );
    },
  );
}

class _MembershipStatusCard extends StatefulWidget {
  final bool added;

  const _MembershipStatusCard({required this.added});

  @override
  State<_MembershipStatusCard> createState() => _MembershipStatusCardState();
}

class _MembershipStatusCardState extends State<_MembershipStatusCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconController;
  late final Animation<double> _iconScale;
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconScale = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );
    _iconController.forward();

    _autoClose = Timer(const Duration(milliseconds: 1600), () {
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final added = widget.added;
    final color = added ? Colors.greenAccent.shade400 : Colors.redAccent;
    final icon = added ? Icons.check_circle_rounded : Icons.remove_circle_rounded;
    final title = added ? "Membership Applied! 🎉" : "Membership Removed";
    final subtitle = added
        ? "Enjoy unlimited free deliveries"
        : "You can add it back anytime";

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 48),
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _iconScale,
                child: Icon(icon, color: color, size: 64),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

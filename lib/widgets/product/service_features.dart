import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../utils/app_colors.dart';

class ServiceFeatures extends StatelessWidget {
  const ServiceFeatures({super.key});

  static const _features = [
    {
      'icon': CupertinoIcons.arrow_counterclockwise,
      'title': '10-Day\nReturns',
      'subtitle': 'Hassle-free',
    },
    {
      'icon': Icons.payments_outlined,
      'title': 'Cash on\nDelivery',
      'subtitle': 'Available',
    },
    {
      'icon': CupertinoIcons.chat_bubble_2,
      'title': '24/7\nSupport',
      'subtitle': 'Always here',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          // ── Feature tiles ─────────────────────────────────────────────
          Row(
            children: _features.map<Widget>((f) {
              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon circle
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bg,
                        border: Border.all(
                          color: AppColors.green.withOpacity(0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        f['icon'] as IconData,
                        color: AppColors.green,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      f['title'] as String,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      f['subtitle'] as String,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),

          // ── "Powered by Dashly" footer ────────────────────────────────
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Secured & fulfilled by ',
                style: TextStyle(color: AppColors.greyDark, fontSize: 10),
              ),
              Text(
                'Dashly',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

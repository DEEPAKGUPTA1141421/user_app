import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ServiceFeatures extends StatelessWidget {
  const ServiceFeatures({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final screenWidth = MediaQuery.of(context).size.width;
    const brandColor = Color(0xFFFF5200);
    final features = [
      {
        'icon': CupertinoIcons.refresh,
        'title': '10-Day Return Policy',
        'link': true,
      },
      {
        'icon': CupertinoIcons.money_dollar,
        'title': 'Cash on Delivery Available',
        'link': true,
      },
      {
        'icon': CupertinoIcons.clock,
        'title': '24/7 Customer Support Service',
        'link': true,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16), // Top & bottom margin
      child: Column(
        children: [
          // Top horizontal line
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),

          // Features Row
          SizedBox(
            width: screenWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: features.map((feature) {
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      // TODO: handle feature click
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon Circle
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: brandColor.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            feature['icon'] as IconData,
                            color: brandColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Text + Chevron
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                feature['title'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (feature['link'] == true)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 14,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Bottom horizontal line
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}

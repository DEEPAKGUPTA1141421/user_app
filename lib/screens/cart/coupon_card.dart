import 'package:flutter/material.dart';

class CouponCard extends StatefulWidget {
  final Map<String, dynamic> coupon;
  final Color brandColor;
  final Function(String) onApply;
  final bool disable;
  final String currentappliedCouponOnCart;

  const CouponCard(
      {super.key,
      required this.coupon,
      required this.brandColor,
      required this.onApply,
      required this.disable,
      required this.currentappliedCouponOnCart});

  @override
  State<CouponCard> createState() => _CouponCardState();
}

class _CouponCardState extends State<CouponCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final coupon = widget.coupon;
    final isActive = (coupon['isActive'] ?? true) && !widget.disable;
    final isBest = coupon['isBest'] ?? false;
    final leftParagraph = coupon['leftParagraph'] ?? "";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        // ✅ Grey background when disabled
        color: widget.disable ? Colors.grey.shade200 : Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!widget.disable)
            const BoxShadow(color: Colors.black12, blurRadius: 2),
        ],
      ),
      child: Row(
        children: [
          // ✅ Notch Box (leftParagraph stays aligned here)
          Container(
            width: 48,
            decoration: BoxDecoration(
              color: isActive ? Colors.grey.shade800 : Colors.grey,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                leftParagraph,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (coupon['addMoreDescription'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        coupon['addMoreDescription'],
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.disable
                              ? Colors.grey
                              : (widget.brandColor == Colors.white ? Colors.grey.shade600 : Colors.grey.shade700),
                        ),
                      ),
                    ),
                  if (coupon['code'] != null)
                    Text(
                      coupon['code'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            widget.disable ? Colors.grey : Colors.grey.shade900,
                      ),
                    ),
                  if (coupon['subDescription'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        coupon['subDescription'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.disable
                              ? Colors.grey
                              : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  if (coupon['saveDescription'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        coupon['saveDescription'],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color:
                              widget.disable ? Colors.grey : (widget.brandColor == Colors.white ? Colors.black : widget.brandColor),
                        ),
                      ),
                    ),
                  if (coupon['description'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        coupon['description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.disable
                              ? Colors.grey
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),

                  // Expandable section (only if additionalInfo exists)
                  if (coupon['additionalInfo'] != null && !isBest)
                    Column(
                      children: [
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: widget.disable
                              ? null
                              : () => setState(() => isExpanded = !isExpanded),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isExpanded ? "- MORE" : "+ MORE",
                                style: TextStyle(
                                  color: widget.disable
                                      ? Colors.grey
                                      : (widget.brandColor == Colors.white ? Colors.black : widget.brandColor),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: widget.disable
                                    ? Colors.grey
                                    : (widget.brandColor == Colors.white ? Colors.black : widget.brandColor),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        if (isExpanded && !widget.disable)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                coupon['additionalInfo'] ?? '',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // ✅ Apply Button (disabled when widget.disable == true)
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: (!isActive || widget.disable)
                  ? null
                  : () {
                      final code = (coupon['code'] ?? '') as String;
                      if (widget.currentappliedCouponOnCart == code) {
                        widget.onApply(''); // 🔹 Remove coupon
                      } else {
                        widget.onApply(code); // 🔹 Apply coupon
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: (!isActive || widget.disable)
                    ? Colors.grey
                    : (widget.currentappliedCouponOnCart == (coupon['code'] ?? '')
                        ? Colors.red
                        : (widget.brandColor == Colors.white ? Colors.white : widget.brandColor)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                widget.currentappliedCouponOnCart == (coupon['code'] ?? '')
                    ? "REMOVE"
                    : "APPLY",
                style: TextStyle(
                  color: (widget.currentappliedCouponOnCart == (coupon['code'] ?? ''))
                      ? Colors.white
                      : (widget.brandColor == Colors.white ? Colors.black : Colors.white),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

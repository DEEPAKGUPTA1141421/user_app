import 'package:flutter/material.dart';
import 'address_selector.dart'; // your DeliveryAddressSelector file

void showAddressModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.75, // 75% height on open
        minChildSize: 0.0, // Can collapse completely
        maxChildSize: 1.0, // Can expand to full screen
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: DeliveryAddressSelector(
              onClose: () => Navigator.pop(context),
              onAddressSelect: (address) {
                debugPrint('Selected address: ${address.name}');
                Navigator.pop(context);
              },
            ),
          );
        },
      );
    },
  );
}

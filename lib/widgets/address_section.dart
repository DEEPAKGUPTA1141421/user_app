import 'package:flutter/material.dart';
import './show_address_modal.dart';

class AddressSection extends StatelessWidget {
  const AddressSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showAddressModal(context),
      child: Container(
        color: Colors.orange,
        padding: const EdgeInsets.all(12),
        height: 40,
        child: Row(
          children: const [
            Icon(Icons.location_on, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Deliver to John - 123 Main Street, City",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

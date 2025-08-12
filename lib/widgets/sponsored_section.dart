import 'package:flutter/material.dart';

class SponsoredSection extends StatelessWidget {
  const SponsoredSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(8),
      color: Colors.redAccent,
      child: const Center(
        child: Text(
          "Sponsored Content",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}

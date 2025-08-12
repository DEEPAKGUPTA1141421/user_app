import 'package:flutter/material.dart';

class BannerSection extends StatelessWidget {
  const BannerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      color: Colors.blue,
      child: const Center(
        child: Text(
          "Banner Placeholder",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}

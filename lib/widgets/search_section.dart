import 'package:flutter/material.dart';
import 'speech_search_page.dart';
import 'real_search_page.dart';
import 'package:flutter/cupertino.dart';

class SearchSection extends StatefulWidget {
  const SearchSection({super.key});

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection> {
  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFFF5200);

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              cursorColor: brandColor, // 🔥 cursor color
              decoration: InputDecoration(
                hintText: "Search for products, brands and more",
                hintStyle: const TextStyle(
                  color: Colors.black, // <-- black color for hint text
                ),
                prefixIcon: const Icon(
                  CupertinoIcons.search,
                  size: 20,
                  color: Color(0xFFFF5200), // 🔥 brand color
                ),
                suffixIcon: const Icon(
                  CupertinoIcons.mic,
                  size: 20,
                  color: Color(0xFFFF5200), // 🔥 brand color
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: brandColor), // 🔥 default border
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: brandColor), // 🔥 enabled border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: brandColor, width: 2), // 🔥 focused border
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.qrcode,
              size: 24,
              color: brandColor, // 🔥 QR icon in brand color
            ),
          ),
        ],
      ),
    );
  }
}

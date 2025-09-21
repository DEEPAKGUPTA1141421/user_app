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
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search for products, brands and more",
                prefixIcon: const Icon(CupertinoIcons.search, size: 20),
                suffixIcon: const Icon(CupertinoIcons.mic, size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(CupertinoIcons.qrcode, size: 24, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}

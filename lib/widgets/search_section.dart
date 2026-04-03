import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'speech_search_page.dart';
import 'real_search_page.dart';
import '../utils/app_colors.dart'; 

class SearchSection extends StatefulWidget {
  const SearchSection({super.key});

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          // ───────── SEARCH BAR ─────────
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RealSearchPage(),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.search,
                      color: AppColors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 10),

                    // Hint text
                    const Expanded(
                      child: Text(
                        "Search for products, brands...",
                        style: TextStyle(
                          color: AppColors.greyDark,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // 🎤 Voice search
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SpeechSearchPage(),
                          ),
                        );
                      },
                      child: const Icon(
                        CupertinoIcons.mic_fill,
                        color: AppColors.grey,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ───────── QR SCANNER ─────────
          GestureDetector(
            onTap: () {
              // TODO: Add QR Scanner navigation
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                CupertinoIcons.qrcode_viewfinder,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
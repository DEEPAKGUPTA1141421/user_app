import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class BannerNotifier extends StateNotifier<Map<String, dynamic>> {
  BannerNotifier()
      : super({
          'isLoading': false,
          'success': false,
          'message': '',
          'banners': [],
          'currentCategoryId': null,
        });

  Future<void> fetchBannersByCategory(String categoryId) async {
    try {
      // Skip if same category already loaded
      if (state['currentCategoryId'] == categoryId &&
          (state['banners'] as List).isNotEmpty) {
        return;
      }

      state = {
        ...state,
        'isLoading': true,
        'message': '',
        'banners': [],
        'currentCategoryId': categoryId,
      };

      final uri = Uri.parse('http://localhost:8081/api/v1/banners').replace(
        queryParameters: {'categoryId': categoryId},
      );

      final res = await http.get(uri, headers: {'Content-Type': 'application/json'});

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == true) {
          state = {
            ...state,
            'isLoading': false,
            'success': true,
            'message': body['message'] ?? '',
            'banners': body['data'] as List? ?? [],
          };
        } else {
          state = {
            ...state,
            'isLoading': false,
            'success': false,
            'message': body['message'] ?? 'Failed to fetch banners',
            'banners': [],
          };
        }
      } else {
        state = {
          ...state,
          'isLoading': false,
          'success': false,
          'message': 'Error: ${res.statusCode}',
          'banners': [],
        };
      }
    } catch (e) {
      state = {
        ...state,
        'isLoading': false,
        'success': false,
        'message': 'Exception: ${e.toString()}',
        'banners': [],
      };
    }
  }

  // ✅ clearBanners is now a no-op if already clear — avoids spurious
  //    state mutations that can trigger "modified during build" errors.
  void clearBanners() {
    if ((state['banners'] as List).isEmpty && state['currentCategoryId'] == null) {
      return; // already clear, skip mutation
    }
    state = {
      ...state,
      'isLoading': false,
      'banners': [],
      'currentCategoryId': null,
    };
  }
}

final bannerProvider =
    StateNotifierProvider<BannerNotifier, Map<String, dynamic>>(
  (ref) => BannerNotifier(),
);
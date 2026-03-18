import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constant/ServerApi.dart';
import '../utils/StorageService.dart';

class CategorySectionsNotifier extends StateNotifier<Map<String, dynamic>> {
  CategorySectionsNotifier()
      : super({
          // ── Separate loading flags so each fetch doesn't stomp others ──
          'categoriesLoading': false,
          'sectionsLoading': false,
          'brandsLoading': false,
          // Keep a single isLoading for legacy watchers (true if ANY loading)
          'isLoading': false,
          'success': false,
          'message': '',
          'categoryData': [],
          'sectionsData': [],
          'brands': [],
        }) {
    // ✅ Only fetch top-level categories once on startup — NOT sections/brands.
    //    Sections and brands are fetched on demand by CategoryPage.
    fetchCategories(false, 'SUPER_CATEGORY');
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  void _setLoading(String key, bool val) {
    final categoriesLoading = key == 'categoriesLoading' ? val : (state['categoriesLoading'] ?? false);
    final sectionsLoading   = key == 'sectionsLoading'   ? val : (state['sectionsLoading']   ?? false);
    final brandsLoading     = key == 'brandsLoading'     ? val : (state['brandsLoading']     ?? false);
    state = {
      ...state,
      key: val,
      'isLoading': categoriesLoading || sectionsLoading || brandsLoading,
    };
  }

  // ── Fetch categories (top-level sidebar list) ─────────────────────────────

  Future<void> fetchCategories(bool includeChildItem, String level) async {
    try {
      _setLoading('categoriesLoading', true);
      final token = await StorageService.getToken();
      final uri = Uri.parse(ServerApi.GetCategory).replace(
        queryParameters: {
          'includeChildItem': includeChildItem.toString(),
          'level': level,
        },
      );
      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      final body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final categories = List<Map<String, dynamic>>.from(body['data'] ?? []);
        state = {
          ...state,
          'categoriesLoading': false,
          'isLoading': (state['sectionsLoading'] ?? false) || (state['brandsLoading'] ?? false),
          'categoryData': categories,
        };
      } else {
        _setLoading('categoriesLoading', false);
      }
    } catch (e) {
      debugPrint('fetchCategories error: $e');
      _setLoading('categoriesLoading', false);
    }
  }

  // ── Fetch sections for a category ─────────────────────────────────────────
  // ✅ Accepts optional categoryId — hits the category-specific endpoint when
  //    provided, otherwise falls back to the default "For You" endpoint.

  Future<void> fetchSectionsOfCategory({String? categoryId}) async {
    try {
      // Clear old sections immediately so the UI shows a loader
      state = {
        ...state,
        'sectionsLoading': true,
        'isLoading': true,
        'sectionsData': [],
      };

      final token = await StorageService.getToken();

      final String url = (categoryId != null && categoryId.isNotEmpty)
          ? '${ServerApi.productClientService}/api/v1/sections/$categoryId'
          : ServerApi.GetSectionOfCategory; // /api/v1/sections/For You

      debugPrint('📡 fetchSectionsOfCategory → $url');

      final res = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      final body = json.decode(res.body);
      debugPrint('fetchSections status=${res.statusCode} success=${body['success']}');

      if (res.statusCode == 200 && body['success'] == true) {
        final sections = List<Map<String, dynamic>>.from(body['data'] ?? []);
        state = {
          ...state,
          'sectionsLoading': false,
          'isLoading': (state['categoriesLoading'] ?? false) || (state['brandsLoading'] ?? false),
          'success': true,
          'sectionsData': sections,
        };
        debugPrint('✅ sections fetched: ${sections.length}');
      } else {
        state = {
          ...state,
          'sectionsLoading': false,
          'isLoading': (state['categoriesLoading'] ?? false) || (state['brandsLoading'] ?? false),
          'success': false,
          'sectionsData': [],
          'message': body['message'] ?? 'Failed to load sections',
        };
      }
    } catch (e) {
      debugPrint('fetchSections error: $e');
      state = {
        ...state,
        'sectionsLoading': false,
        'isLoading': (state['categoriesLoading'] ?? false) || (state['brandsLoading'] ?? false),
        'success': false,
        'sectionsData': [],
        'message': e.toString(),
      };
    }
  }

  // ── Fetch brands for a category ───────────────────────────────────────────

  Future<void> fetchBrands(String categoryId) async {
    try {
      debugPrint('📡 fetchBrands → categoryId=$categoryId');
      // Clear old brands immediately
      state = {
        ...state,
        'brandsLoading': true,
        'isLoading': true,
        'brands': [],
      };

      final token = await StorageService.getToken();
      final res = await http.get(
        Uri.parse('${ServerApi.getBrands}/$categoryId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = json.decode(res.body);

      List<Map<String, dynamic>> brands = [];
      if (body is List) {
        brands = List<Map<String, dynamic>>.from(body);
      } else if (body is Map<String, dynamic>) {
        if (body['data'] is List) {
          brands = List<Map<String, dynamic>>.from(body['data']);
        } else if (body['success'] == true) {
          brands = [body];
        }
      }

      state = {
        ...state,
        'brandsLoading': false,
        'isLoading': (state['categoriesLoading'] ?? false) || (state['sectionsLoading'] ?? false),
        'brands': brands,
      };
      debugPrint('✅ brands fetched: ${brands.length}');
    } catch (e) {
      debugPrint('fetchBrands error: $e');
      state = {
        ...state,
        'brandsLoading': false,
        'isLoading': (state['categoriesLoading'] ?? false) || (state['sectionsLoading'] ?? false),
        'brands': [],
        'message': e.toString(),
      };
    }
  }
}

final categorySectionsProvider =
    StateNotifierProvider<CategorySectionsNotifier, Map<String, dynamic>>(
  (ref) => CategorySectionsNotifier(),
);
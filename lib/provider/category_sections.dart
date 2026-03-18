import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constant/ServerApi.dart';
import '../utils/StorageService.dart';

class CategorySectionsNotifier extends StateNotifier<Map<String, dynamic>> {
  CategorySectionsNotifier()
      : super({
          'isLoading': false,
          'success': false,
          'message': '',
          'categoryData': [],
          'sectionsData': [],
          'brands': [],
        }) {
    // Fetch top-level super categories on startup
    fetchCategories(true, "SUPER_CATEGORY");
  }

  // ─── Fetch categories ───────────────────────────────────────────────────────

  Future<void> fetchCategories(bool includeChildItem, String level) async {
    try {
      state = {...state, 'isLoading': true, 'message': ''};
      final token = await StorageService.getToken();
      final uri = Uri.parse(ServerApi.GetCategory).replace(
        queryParameters: {
          'includeChildItem': includeChildItem.toString(),
          'level': level,
        },
      );
      final res = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final body = json.decode(res.body);
      debugPrint("Categories fetched: ${res.statusCode}");

      if (res.statusCode == 200 && body['success'] == true) {
        final List<Map<String, dynamic>> categories =
            List<Map<String, dynamic>>.from(body['data'] ?? []);
        state = {
          ...state,
          'isLoading': false,
          'success': true,
          'message': body['message'] ?? '',
          'categoryData': categories,
        };
      } else {
        state = {
          ...state,
          'isLoading': false,
          'success': false,
          'message': body['message'] ?? 'Failed to load categories',
        };
      }
    } catch (e) {
      state = {
        ...state,
        'isLoading': false,
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // ─── Fetch sections ─────────────────────────────────────────────────────────
  // ✅ Now accepts an optional categoryId so clicking a category re-fetches
  // its own sections. Falls back to "For You" when no categoryId is provided.

  Future<void> fetchSectionsOfCategory({String? categoryId}) async {
    try {
      state = {...state, 'isLoading': true, 'message': '', 'sectionsData': []};
      final token = await StorageService.getToken();

      // Build URL — use the category-specific endpoint when a categoryId is
      // provided, otherwise fall back to the default "For You" endpoint.
      final String url = categoryId != null && categoryId.isNotEmpty
          ? '${ServerApi.productClientService}/api/v1/sections/$categoryId'
          : ServerApi.GetSectionOfCategory; // e.g. /api/v1/sections/For You

      debugPrint("Fetching sections from: $url");

      final res = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        final List<Map<String, dynamic>> sections =
            List<Map<String, dynamic>>.from(body['data'] ?? []);

        state = {
          ...state,
          'isLoading': false,
          'success': true,
          'sectionsData': sections,
          'message': body['message'] ?? '',
        };

        debugPrint("✅ Sections fetched: ${sections.length} for category: $categoryId");
      } else {
        state = {
          ...state,
          'isLoading': false,
          'success': false,
          'sectionsData': [],
          'message': body['message'] ?? 'Failed to load sections',
        };
      }
    } catch (e) {
      state = {
        ...state,
        'isLoading': false,
        'success': false,
        'sectionsData': [],
        'message': e.toString(),
      };
    }
  }

  // ─── Fetch brands ───────────────────────────────────────────────────────────

  Future<void> fetchBrands(String categoryId) async {
    try {
      debugPrint("🔄 Fetching brands for category: $categoryId");

      state = {...state, 'isLoading': true, 'message': '', 'brands': []};
      final token = await StorageService.getToken();

      final res = await http.get(
        Uri.parse("${ServerApi.getBrands}/$categoryId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final body = json.decode(res.body);

      List<Map<String, dynamic>> brands = [];
      if (body is List) {
        brands = List<Map<String, dynamic>>.from(body);
      } else if (body is Map<String, dynamic>) {
        // Some APIs wrap in { data: [...] }
        if (body['data'] is List) {
          brands = List<Map<String, dynamic>>.from(body['data']);
        } else {
          brands = [body];
        }
      }

      state = {
        ...state,
        'isLoading': false,
        'success': true,
        'message': '',
        'brands': brands,
      };

      debugPrint("✅ Brands fetched: ${brands.length} for category: $categoryId");
    } catch (e) {
      debugPrint("❌ Brand fetch error: $e");
      state = {
        ...state,
        'isLoading': false,
        'success': false,
        'message': e.toString(),
        'brands': [],
      };
    }
  }
}

// ✅ Riverpod provider
final categorySectionsProvider =
    StateNotifierProvider<CategorySectionsNotifier, Map<String, dynamic>>(
  (ref) => CategorySectionsNotifier(),
);
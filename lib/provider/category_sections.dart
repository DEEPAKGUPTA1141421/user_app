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
    fetchCategories(true, "SUPER_CATEGORY");
  }

  /// ✅ Fetch all categories
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
      print("data from category ${body}");
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

  /// ✅ Fetch all sections of a category
  Future<void> fetchSectionsOfCategory() async {
    try {
      state = {...state, 'isLoading': true, 'message': ''};
      final token = await StorageService.getToken();

      final res = await http.get(
        Uri.parse(ServerApi.GetSectionOfCategory),
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

        debugPrint("✅ Sections fetched: ${sections.length}");
      } else {
        state = {
          ...state,
          'isLoading': false,
          'success': false,
          'message': body['message'] ?? 'Failed to load sections',
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

  /// ✅ Fetch brands for a specific category
  Future<void> fetchBrands(String categoryId) async {
    try {
      debugPrint("🔄 Fetching brands for category: $categoryId");

      state = {...state, 'isLoading': true, 'message': ''};
      final token = await StorageService.getToken();

      final res = await http.get(
        Uri.parse(
            "${ServerApi.getBrands}/5d70fc95-8a6b-4d04-95e9-9620269ab15e"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final body = json.decode(res.body);

      // Ensure brands is always a list
      List<Map<String, dynamic>> brands = [];
      if (body is List) {
        brands = List<Map<String, dynamic>>.from(body);
      } else if (body is Map<String, dynamic>) {
        brands = [body]; // wrap single object into a list
      } else {
        throw Exception("Unexpected API response format");
      }

      state = {
        ...state,
        'isLoading': false,
        'success': true,
        'message': '',
        'brands': brands,
      };

      debugPrint("✅ Brands fetched: ${brands}");
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

/// ✅ Riverpod provider
final categorySectionsProvider =
    StateNotifierProvider<CategorySectionsNotifier, Map<String, dynamic>>(
  (ref) => CategorySectionsNotifier(),
);

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constant/ServerApi.dart';
import '../utils/StorageService.dart';

class CategoryNotifier extends StateNotifier<Map<String, dynamic>> {
  CategoryNotifier()
      : super({
          'isLoading': false,
          'success': false,
          'message': '',
          'categoryData': [],
        }) {
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      state = {...state, 'isLoading': true, 'message': ''};

      final token = await StorageService.getAccessToken();
      final response = await http.get(
        Uri.parse('${ServerApi.GetCategory}?includeChildItem=false&level=SUPER_CATEGORY'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("response from backend for category ${response.statusCode}");
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        print("response from backend for category ${body}");
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
          'message': 'Failed to load categories',
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
}

// Riverpod provider
final categoryProvider =
    StateNotifierProvider<CategoryNotifier, Map<String, dynamic>>(
        (ref) => CategoryNotifier());

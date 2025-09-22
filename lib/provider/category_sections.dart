import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constant/ServerApi.dart';
import '../utils/StorageService.dart';

class categorySectionsProvider extends StateNotifier<Map<String, dynamic>> {
  categorySectionsProvider()
      : super({
          'isLoading': false,
          'success': false,
          'message': '',
          'categoryData': [],
          'sectionsData': [],
        }) {
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      state = {...state, 'isLoading': true, 'message': ''};

      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse(ServerApi.GetCategory),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
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

  Future<void> fetchSectionsOfCategory() async {
    try {
      state = {...state, 'isLoading': true, 'message': ''};

      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse(ServerApi.GetSectionOfCategory),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        debugPrint("body check ${body['data']}");
        final List<Map<String, dynamic>> sections =
            List<Map<String, dynamic>>.from(body['data'] ?? []);

        state = {
          ...state,
          'isLoading': false,
          'success': true,
          'message': body['message'] ?? '',
          'sectionsData': sections, // for rendering CategoryPage
        };
      } else {
        state = {
          ...state,
          'isLoading': false,
          'success': false,
          'message': 'Failed to load sections',
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
final categorySection =
    StateNotifierProvider<categorySectionsProvider, Map<String, dynamic>>(
        (ref) => categorySectionsProvider());

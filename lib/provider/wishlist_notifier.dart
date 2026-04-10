import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constant/ServerApi.dart';
import '../utils/StorageService.dart';

class WishlistNotifier extends StateNotifier<Map<String, dynamic>> {
  WishlistNotifier()
      : super({
          'isLoading': false,
          'success': false,
          'message': '',
          'items': [],
          'priceDrops': [],
          'shareUrl': null,
        });

  Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Fetch wishlist items
  Future<void> fetchWishlist() async {
    try {
      state = {...state, 'isLoading': true, 'message': ''};
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse('${ServerApi.productClientService}/api/v1/wishlist'),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final data = body['data'] ?? {};
        final rawItems = (data['items'] ?? []) as List<dynamic>;

        state = {
          ...state,
          'isLoading': false,
          'success': body['success'] ?? false,
          'items': rawItems,
          'message': body['message'] ?? '',
        };
      } else {
        state = {
          ...state,
          'isLoading': false,
          'success': false,
          'message': 'Failed to load wishlist',
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

  /// Add item to wishlist
  Future<Map<String, dynamic>> addItem(String productId, {String? variantId}) async {
    try {
      state = {...state, 'isLoading': true};
      final headers = await _authHeaders();

      String url = '${ServerApi.productClientService}/api/v1/wishlist/items/$productId';
      if (variantId != null) url += '?variantId=$variantId';

      final res = await http.post(Uri.parse(url), headers: headers);
      final body = json.decode(res.body);

      if (res.statusCode == 200) {
        await fetchWishlist();
      }
      state = {...state, 'isLoading': false};
      return body;
    } catch (e) {
      state = {...state, 'isLoading': false};
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Remove item from wishlist
  Future<Map<String, dynamic>> removeItem(String productId) async {
    try {
      state = {...state, 'isLoading': true};
      final headers = await _authHeaders();

      final res = await http.delete(
        Uri.parse('${ServerApi.productClientService}/api/v1/wishlist/items/$productId'),
        headers: headers,
      );

      final body = json.decode(res.body);

      if (res.statusCode == 200) {
        // Optimistically remove from local list
        final currentItems = List<dynamic>.from(state['items']);
        currentItems.removeWhere((item) =>
            item['productId']?.toString() == productId ||
            item['id']?.toString() == productId);
        state = {...state, 'isLoading': false, 'items': currentItems};
      } else {
        state = {...state, 'isLoading': false};
      }
      return body;
    } catch (e) {
      state = {...state, 'isLoading': false};
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Clear entire wishlist
  Future<Map<String, dynamic>> clearWishlist() async {
    try {
      state = {...state, 'isLoading': true};
      final headers = await _authHeaders();

      final res = await http.delete(
        Uri.parse('${ServerApi.productClientService}/api/v1/wishlist'),
        headers: headers,
      );

      final body = json.decode(res.body);
      state = {
        ...state,
        'isLoading': false,
        'items': res.statusCode == 200 ? [] : state['items'],
      };
      return body;
    } catch (e) {
      state = {...state, 'isLoading': false};
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Move item to cart
  Future<Map<String, dynamic>> moveToCart(String productId) async {
    try {
      state = {...state, 'isLoading': true};
      final headers = await _authHeaders();

      final res = await http.post(
        Uri.parse('${ServerApi.productClientService}/api/v1/wishlist/$productId/move-to-cart'),
        headers: headers,
      );

      final body = json.decode(res.body);

      if (res.statusCode == 200) {
        // Remove from wishlist locally
        final currentItems = List<dynamic>.from(state['items']);
        currentItems.removeWhere((item) =>
            item['productId']?.toString() == productId);
        state = {...state, 'isLoading': false, 'items': currentItems};
      } else {
        state = {...state, 'isLoading': false};
      }
      return body;
    } catch (e) {
      state = {...state, 'isLoading': false};
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Fetch price drops
  Future<void> fetchPriceDrops() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse('${ServerApi.productClientService}/api/v1/wishlist/price-drops'),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final data = (body['data'] ?? []) as List<dynamic>;
        state = {...state, 'priceDrops': data};
      }
    } catch (e) {
      // silently fail, price drops are non-critical
    }
  }

  /// Share wishlist
  Future<Map<String, dynamic>> shareWishlist({int? ttlDays}) async {
    try {
      state = {...state, 'isLoading': true};
      final headers = await _authHeaders();

      String url = '${ServerApi.productClientService}/api/v1/wishlist/share';
      if (ttlDays != null) url += '?ttlDays=$ttlDays';

      final res = await http.post(Uri.parse(url), headers: headers);
      final body = json.decode(res.body);

      state = {...state, 'isLoading': false};
      return body;
    } catch (e) {
      state = {...state, 'isLoading': false};
      return {'success': false, 'message': e.toString()};
    }
  }
}

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, Map<String, dynamic>>(
  (ref) => WishlistNotifier(),
);
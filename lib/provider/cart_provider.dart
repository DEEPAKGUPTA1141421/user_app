import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constant/ServerApi.dart';
import '../utils/StorageService.dart';

class CartNotifier extends StateNotifier<Map<String, dynamic>> {
  CartNotifier()
      : super({
          'isLoading': false,
          'success': false,
          'message': '',
          'cartData': {},
          'moreCoupons':[],
          'bestCoupons':[]
        }) {}

  /// Fetch the active cart
  Future<void> fetchCart() async {
    try {
      state = {...state, 'isLoading': true, 'message': ''};

      final token = await StorageService.getAccessToken();
      final response = await http.get(
        Uri.parse(ServerApi.getCart),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        state = {
          ...state,
          'isLoading': false,
          'success': body['success'] ?? false,
          'message': body['message'] ?? '',
          'cartData': body['data'] ?? {},
        };
        print("jsonbody ${body}");
      } else {
        state = {
          ...state,
          'isLoading': false,
          'success': false,
          'message': 'Failed to load cart',
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

  Future<void> updateCartItem(String itemId, int qty) async {
    try {
      state = {...state, 'isLoading': true, 'message': ''};

      final token = await StorageService.getAccessToken();
      final url =
          Uri.parse("${ServerApi.updateItemQtyToCart}/$itemId?qty=$qty");
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        state = {
          ...state,
          'isLoading': false,
          'success': body['success'] ?? false,
          'message': body['message'] ?? '',
          'cartData': body['data'] ?? {},
        };
        print("jsonbody ${body}");
      } else {
        state = {
          ...state,
          'isLoading': false,
          'success': false,
          'message': 'Failed to load cart',
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

  /// Add item to cart
  Future<void> addItem(Map<String, dynamic> itemRequest) async {
    try {
      state = {...state, 'isLoading': true};

      final token = await StorageService.getAccessToken();
      final response = await http.post(
        Uri.parse(ServerApi.getCart),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(itemRequest),
      );

      if (response.statusCode == 201) {
        await fetchCart(); // Refresh cart
      } else {
        state = {
          ...state,
          'isLoading': false,
          'message': 'Failed to add item',
        };
      }
    } catch (e) {
      state = {...state, 'isLoading': false, 'message': e.toString()};
    }
  }

  /// Remove item from cart
  Future<void> removeItem(String itemId) async {
    try {
      state = {...state, 'isLoading': true};

      final token = await StorageService.getAccessToken();
      final url = Uri.parse("${ServerApi.removeItemFromCart}/$itemId");
      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchCart(); // Refresh cart
      } else {
        state = {
          ...state,
          'isLoading': false,
          'message': 'Failed to remove item',
        };
      }
    } catch (e) {
      state = {...state, 'isLoading': false, 'message': e.toString()};
    }
  }

  /// Clear cart
  Future<void> clearCart() async {
    try {
      state = {...state, 'isLoading': true};

      final token = await StorageService.getAccessToken();
      final response = await http.delete(
        Uri.parse(ServerApi.getCart),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        state = {
          ...state,
          'isLoading': false,
          'success': true,
          'cartData': {},
          'message': 'Cart cleared',
        };
      } else {
        state = {
          ...state,
          'isLoading': false,
          'message': 'Failed to clear cart',
        };
      }
    } catch (e) {
      state = {...state, 'isLoading': false, 'message': e.toString()};
    }
  }

  Future<void> cartCoupon() async {
    try {
      state = {...state, 'isLoading': true};

      final token = await StorageService.getAccessToken();
      final response = await http.get(
        Uri.parse(ServerApi.cartCoupon),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      print("Coupons ${response}");
      if (response.statusCode == 200) {
         final body = json.decode(response.body);
         print("Coupons ${body}");
        state = {
          ...state,
          'isLoading': false,
          'success': true,
          'message': 'Cart cleared',
          'bestCoupons':body['data']['bestCoupons'],
          'moreCoupons':body['data']['moreCoupons']
        };
      } else {
        state = {
          ...state,
          'isLoading': false,
          'message': 'Failed to fetch cart Coupon',
        };
      }
    } catch (e) {
      state = {...state, 'isLoading': false, 'message': e.toString()};
    }
  }
  Future<void> ApplyCartCoupon(String couponCode) async {
    try {
      state = {...state, 'isLoading': true, 'message': ''};

      final token = await StorageService.getAccessToken();
      final response = await http.post(
        Uri.parse("${ServerApi.ApplyCartCoupon}/${couponCode}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      print("called applycoupon");
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        print("response of apply coupon ${body}");
        state = {
          ...state,
          'isLoading': false,
          'success': body['success'] ?? false,
          'message': body['message'] ?? '',
          'cartData': body['data'] ?? {},
        };
      } else {
        state = {
          ...state,
          'isLoading': false,
          'success': false,
          'message': 'Failed to Apply Coupon',
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

/// Riverpod provider
final cartProvider = StateNotifierProvider<CartNotifier, Map<String, dynamic>>(
    (ref) => CartNotifier());

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constant/ServerApi.dart';
import '../utils/StorageService.dart';

class ProductNotifier extends StateNotifier<Map<String, dynamic>> {
  ProductNotifier()
      : super({
          'isLoading': false,
          'success': false,
          'message': '',
          'products': [],
          'product_detail': {},
          'brands': [],
          'Infinite_Scroll_Products': [],
        });

  bool get isLoading => state['isLoading'] ?? false;

  /// ✅ Fetch product detail
  Future<Map<String, dynamic>> fetchProductDetail(String productId) async {
    state = {...state, 'isLoading': true};

    final token = await StorageService.getToken();

    final res = await http.get(
      Uri.parse("${ServerApi.getProductDetail}/$productId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final Map<String, dynamic> jsonBody = jsonDecode(res.body);

    state = {
      ...state,
      'isLoading': false,
      'success': jsonBody['success'] ?? false,
      'message': jsonBody['message'] ?? '',
      'product_detail': jsonBody['data'] ?? {},
    };

    return jsonBody;
  }

  /// ✅ Fetch all products
  Future<Map<String, dynamic>> fetchProducts() async {
    state = {...state, 'isLoading': true};

    final res = await http.get(
      Uri.parse(ServerApi.getProducts),
      headers: {"Content-Type": "application/json"},
    );

    final Map<String, dynamic> jsonBody = jsonDecode(res.body);

    state = {
      ...state,
      'isLoading': false,
      'success': jsonBody['success'] ?? false,
      'message': jsonBody['message'] ?? '',
      'products': jsonBody['data'] ?? [],
    };

    return jsonBody;
  }

  /// ✅ Search product by keyword
  Future<Map<String, dynamic>> searchProduct(String query) async {
    state = {...state, 'isLoading': true};

    final res = await http.get(
      Uri.parse("${ServerApi.searchProduct}?keyword=$query"),
      headers: {"Content-Type": "application/json"},
    );

    final Map<String, dynamic> jsonBody = jsonDecode(res.body);

    // ✅ Extract correctly from nested "data"
    final data = jsonBody['data'] ?? {};
    final products = data['products'] ?? [];
    final brands = data['brands'] ?? [];

    state = {
      ...state,
      'isLoading': false,
      'success': jsonBody['success'] ?? false,
      'message': jsonBody['message'] ?? '',
      'products': products,
      'brands': brands,
    };

    print("✅ Data from search: ${jsonBody}");
    print(
        "✅ Brands count: ${brands.length}, Products count: ${products.length}");

    return jsonBody;
  }

  Future<Map<String, dynamic>> saveSearch(
      String itemId, String itemType, String title, String imageUrl,
      {String? meta}) async {
    state = {...state, 'isLoading': true};

    final token = await StorageService.getToken();

    // Build the request body
    final body = jsonEncode({
      "itemId": itemId,
      "itemType": itemType, // make sure it matches backend enum values
      "title": title,
      "imageUrl": imageUrl,
      "meta": meta ?? "",
    });

    final res = await http.post(
      Uri.parse(ServerApi.saveSearch),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body, // ✅ pass JSON body
    );

    final Map<String, dynamic> jsonBody = jsonDecode(res.body);

    state = {
      ...state,
      'isLoading': false,
      'success': jsonBody['success'] ?? false,
      'message': jsonBody['message'] ?? '',
    };

    debugPrint("result of save search ${jsonBody}");
    return jsonBody;
  }

  Future<Map<String, dynamic>> RecentSearchOfUser() async {
    state = {...state, 'isLoading': true};

    final token = await StorageService.getToken();

    final res = await http.get(
      Uri.parse(ServerApi.recentSearchOfUser),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final Map<String, dynamic> jsonBody = jsonDecode(res.body);

    state = {
      ...state,
      'isLoading': false,
      'success': jsonBody['success'] ?? false,
      'message': jsonBody['message'] ?? '',
    };

    print("result of Recent search ${jsonBody}");
    return jsonBody;
  }

  Future<Map<String, dynamic>> TrendingSearch() async {
    state = {...state, 'isLoading': true};

    final token = await StorageService.getToken();

    final res = await http.get(
      Uri.parse(ServerApi.TrendingSearch),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final Map<String, dynamic> jsonBody = jsonDecode(res.body);

    state = {
      ...state,
      'isLoading': false,
      'success': jsonBody['success'] ?? false,
      'message': jsonBody['message'] ?? '',
    };

    print("result of TrendingSearch ${jsonBody}");
    return jsonBody;
  }
}

/// ✅ Global provider
final productPod = StateNotifierProvider<ProductNotifier, Map<String, dynamic>>(
  (ref) => ProductNotifier(),
);

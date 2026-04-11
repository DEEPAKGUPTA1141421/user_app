import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';

// ── Typed State ───────────────────────────────────────────────────────────────

class CategoryState {
  final bool isLoading;
  final String? error;
  final List<dynamic> categoryData;

  const CategoryState({
    this.isLoading = false,
    this.error,
    this.categoryData = const [],
  });

  CategoryState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? categoryData,
  }) {
    return CategoryState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      categoryData: categoryData ?? this.categoryData,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class CategoryNotifier extends StateNotifier<CategoryState> {
  CategoryNotifier() : super(const CategoryState()) {
    fetchCategories();
  }

  Dio get _client => ApiClient.instance.productClient;

  Future<void> fetchCategories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.get(
        ApiEndpoints.categoryByLevel,
        queryParameters: {
          'includeChildItem': 'false',
          'level': 'SUPER_CATEGORY',
        },
      );
      final body = res.data as Map<String, dynamic>;
      final categories = (body['data'] as List<dynamic>?) ?? const [];
      state = state.copyWith(isLoading: false, categoryData: categories);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final categoryProvider =
    StateNotifierProvider<CategoryNotifier, CategoryState>(
        (ref) => CategoryNotifier());

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';

// ── Typed State ───────────────────────────────────────────────────────────────

class CategorySectionsState {
  final bool categoriesLoading;
  final bool sectionsLoading;
  final bool brandsLoading;
  final String? error;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> sections;
  final List<Map<String, dynamic>> brands;

  const CategorySectionsState({
    this.categoriesLoading = false,
    this.sectionsLoading   = false,
    this.brandsLoading     = false,
    this.error,
    this.categories = const [],
    this.sections   = const [],
    this.brands     = const [],
  });

  /// True if any sub-fetch is in flight.
  bool get isLoading => categoriesLoading || sectionsLoading || brandsLoading;

  CategorySectionsState copyWith({
    bool? categoriesLoading,
    bool? sectionsLoading,
    bool? brandsLoading,
    String? error,
    List<Map<String, dynamic>>? categories,
    List<Map<String, dynamic>>? sections,
    List<Map<String, dynamic>>? brands,
  }) {
    return CategorySectionsState(
      categoriesLoading: categoriesLoading ?? this.categoriesLoading,
      sectionsLoading:   sectionsLoading   ?? this.sectionsLoading,
      brandsLoading:     brandsLoading     ?? this.brandsLoading,
      error: error,
      categories: categories ?? this.categories,
      sections:   sections   ?? this.sections,
      brands:     brands     ?? this.brands,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class CategorySectionsNotifier extends StateNotifier<CategorySectionsState> {
  CategorySectionsNotifier() : super(const CategorySectionsState()) {
    // Fetch top-level categories once at startup
    fetchCategories(includeChildItem: false, level: 'SUPER_CATEGORY');
  }

  Dio get _client => ApiClient.instance.productClient;

  // ── Fetch categories ──────────────────────────────────────────────────────

  Future<void> fetchCategories({
    required bool includeChildItem,
    required String level,
  }) async {
    state = state.copyWith(categoriesLoading: true, error: null);
    try {
      final res = await _client.get(
        ApiEndpoints.categoryByLevel,
        queryParameters: {
          'includeChildItem': includeChildItem.toString(),
          'level': level,
        },
      );
      final body = res.data as Map<String, dynamic>;
      final raw = (body['data'] as List<dynamic>?) ?? const [];
      state = state.copyWith(
        categoriesLoading: false,
        categories: raw.cast<Map<String, dynamic>>(),
      );
    } on DioException catch (e) {
      state = state.copyWith(
        categoriesLoading: false,
        error: AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(categoriesLoading: false, error: e.toString());
    }
  }

  // ── Fetch sections for a category ─────────────────────────────────────────

  Future<void> fetchSectionsOfCategory({String? categoryId}) async {
    // Clear sections immediately so UI shows loader
    state = state.copyWith(sectionsLoading: true, sections: const [], error: null);
    try {
      final url = (categoryId != null && categoryId.isNotEmpty)
          ? ApiEndpoints.sectionsForCategory(categoryId)
          : ApiEndpoints.sectionsForCategory('For You');

      final res = await _client.get(url);
      final body = res.data as Map<String, dynamic>;
      final raw = (body['data'] as List<dynamic>?) ?? const [];
      state = state.copyWith(
        sectionsLoading: false,
        sections: raw.cast<Map<String, dynamic>>(),
      );
    } on DioException catch (e) {
      state = state.copyWith(
        sectionsLoading: false,
        sections: const [],
        error: AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(
        sectionsLoading: false,
        sections: const [],
        error: e.toString(),
      );
    }
  }

  // ── Fetch brands for a category ───────────────────────────────────────────

  Future<void> fetchBrands(String categoryId) async {
    state = state.copyWith(brandsLoading: true, brands: const [], error: null);
    try {
      final res = await _client.get(
        ApiEndpoints.brandsForCategory(categoryId),
      );
      final body = res.data;
      List<Map<String, dynamic>> brands = const [];

      if (body is List) {
        brands = body.cast<Map<String, dynamic>>();
      } else if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is List) {
          brands = data.cast<Map<String, dynamic>>();
        }
      }

      state = state.copyWith(brandsLoading: false, brands: brands);
    } on DioException catch (e) {
      state = state.copyWith(
        brandsLoading: false,
        brands: const [],
        error: AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(
        brandsLoading: false,
        brands: const [],
        error: e.toString(),
      );
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final categorySectionsProvider = StateNotifierProvider<
    CategorySectionsNotifier, CategorySectionsState>(
  (ref) => CategorySectionsNotifier(),
);

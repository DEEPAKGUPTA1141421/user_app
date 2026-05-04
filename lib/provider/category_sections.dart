import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';

// ── Typed State ───────────────────────────────────────────────────────────────

// ── Browse Models ─────────────────────────────────────────────────────────────

class SubSubCategoryItem {
  final String id;
  final String name;
  final String imageUrl;

  const SubSubCategoryItem({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory SubSubCategoryItem.fromJson(Map<String, dynamic> json) =>
      SubSubCategoryItem(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
      );
}

class BrowseSubcategory {
  final String id;
  final String name;
  final String imageUrl;
  final List<SubSubCategoryItem> subCategories;

  const BrowseSubcategory({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.subCategories,
  });

  factory BrowseSubcategory.fromJson(Map<String, dynamic> json) =>
      BrowseSubcategory(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
        subCategories: ((json['subCategories'] as List?) ?? [])
            .map((e) => SubSubCategoryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ── State ─────────────────────────────────────────────────────────────────────

class CategorySectionsState {
  final bool categoriesLoading;
  final bool sectionsLoading;
  final bool brandsLoading;
  final bool browseLoading;
  final String? error;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> sections;
  final List<Map<String, dynamic>> brands;
  final List<BrowseSubcategory> browseGroups;
  final String? browseActiveSuperCategoryId;

  const CategorySectionsState({
    this.categoriesLoading = false,
    this.sectionsLoading   = false,
    this.brandsLoading     = false,
    this.browseLoading     = false,
    this.error,
    this.categories = const [],
    this.sections   = const [],
    this.brands     = const [],
    this.browseGroups = const [],
    this.browseActiveSuperCategoryId,
  });

  bool get isLoading => categoriesLoading || sectionsLoading || brandsLoading;

  CategorySectionsState copyWith({
    bool? categoriesLoading,
    bool? sectionsLoading,
    bool? brandsLoading,
    bool? browseLoading,
    String? error,
    List<Map<String, dynamic>>? categories,
    List<Map<String, dynamic>>? sections,
    List<Map<String, dynamic>>? brands,
    List<BrowseSubcategory>? browseGroups,
    String? browseActiveSuperCategoryId,
  }) {
    return CategorySectionsState(
      categoriesLoading: categoriesLoading ?? this.categoriesLoading,
      sectionsLoading:   sectionsLoading   ?? this.sectionsLoading,
      brandsLoading:     brandsLoading     ?? this.brandsLoading,
      browseLoading:     browseLoading     ?? this.browseLoading,
      error: error,
      categories: categories ?? this.categories,
      sections:   sections   ?? this.sections,
      brands:     brands     ?? this.brands,
      browseGroups: browseGroups ?? this.browseGroups,
      browseActiveSuperCategoryId:
          browseActiveSuperCategoryId ?? this.browseActiveSuperCategoryId,
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

  // ── Fetch categories from /api/v1/product/category ───────────────────────

  Future<void> fetchCategoryList() async {
    state = state.copyWith(categoriesLoading: true, error: null);
    try {
      final res = await _client.get(ApiEndpoints.categoryList);
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

  Future<void> fetchSectionsOfCategory({
    String? categoryId,
    String? userId,
  }) async {
    state = state.copyWith(sectionsLoading: true, sections: const [], error: null);
    try {
      final url = (categoryId != null && categoryId.isNotEmpty)
          ? ApiEndpoints.sectionsForCategory(categoryId)
          : ApiEndpoints.sectionsForCategory('For You');

      final res = await _client.get(
        url,
        queryParameters: {
          if (userId != null && userId.isNotEmpty) 'userId': userId,
        },
      );
      final body = res.data as Map<String, dynamic>;

      // Handle both response formats:
      //   OLD: { "data": [...] }
      //   NEW: { "success": true, "data": { "sections": [...] } }
      List<Map<String, dynamic>> sections = const [];
      final data = body['data'];
      if (data is List) {
        sections = data.cast<Map<String, dynamic>>();
      } else if (data is Map) {
        final inner = data['sections'];
        if (inner is List) {
          sections = inner.cast<Map<String, dynamic>>();
        }
      }

      state = state.copyWith(sectionsLoading: false, sections: sections);
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

  // ── Fetch browse groups (SUBCATEGORY + SUBSUBCATEGORY) ───────────────────

  Future<void> fetchBrowseCategories(String superCategoryId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        state.browseActiveSuperCategoryId == superCategoryId &&
        state.browseGroups.isNotEmpty) return; // already loaded

    state = state.copyWith(
      browseLoading: true,
      browseActiveSuperCategoryId: superCategoryId,
      browseGroups: const [],
      error: null,
    );
    try {
      final res = await _client.get(
        ApiEndpoints.categoryBrowse(superCategoryId),
      );
      final body = res.data as Map<String, dynamic>;
      final raw = (body['data'] as List?) ?? const [];
      state = state.copyWith(
        browseLoading: false,
        browseGroups: raw
            .map((e) => BrowseSubcategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      state = state.copyWith(
        browseLoading: false,
        error: AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(browseLoading: false, error: e.toString());
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

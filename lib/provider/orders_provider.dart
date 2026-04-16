import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';

// ─── Order List ───────────────────────────────────────────────────────────────

class OrdersState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<Map<String, dynamic>> orders;
  final int currentPage;
  final int totalPages;
  final bool hasNext;

  const OrdersState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.orders = const [],
    this.currentPage = 0,
    this.totalPages = 0,
    this.hasNext = false,
  });

  OrdersState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<Map<String, dynamic>>? orders,
    int? currentPage,
    int? totalPages,
    bool? hasNext,
  }) {
    return OrdersState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      orders: orders ?? this.orders,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasNext: hasNext ?? this.hasNext,
    );
  }
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  OrdersNotifier() : super(const OrdersState());

  Dio get _client => ApiClient.instance.orderClient;
  static const int _pageSize = 10;

  Future<void> fetchOrders({bool refresh = false}) async {
    if (refresh) {
      state = const OrdersState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final res = await _client.get(
        ApiEndpoints.orders,
        queryParameters: {'page': 0, 'size': _pageSize},
      );
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final rawOrders = data['orders'] as List<dynamic>;
      final orders =
          rawOrders.map((o) => Map<String, dynamic>.from(o as Map)).toList();

      state = state.copyWith(
        isLoading: false,
        orders: orders,
        currentPage: (data['currentPage'] as num?)?.toInt() ?? 0,
        totalPages: (data['totalPages'] as num?)?.toInt() ?? 0,
        hasNext: data['hasNext'] as bool? ?? false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
          isLoading: false, error: AppException.fromDioError(e).message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasNext || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final nextPage = state.currentPage + 1;
      final res = await _client.get(
        ApiEndpoints.orders,
        queryParameters: {'page': nextPage, 'size': _pageSize},
      );
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final rawOrders = data['orders'] as List<dynamic>;
      final newOrders =
          rawOrders.map((o) => Map<String, dynamic>.from(o as Map)).toList();

      state = state.copyWith(
        isLoadingMore: false,
        orders: [...state.orders, ...newOrders],
        currentPage: (data['currentPage'] as num?)?.toInt() ?? nextPage,
        totalPages:
            (data['totalPages'] as num?)?.toInt() ?? state.totalPages,
        hasNext: data['hasNext'] as bool? ?? false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
          isLoadingMore: false, error: AppException.fromDioError(e).message);
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, OrdersState>(
  (ref) => OrdersNotifier(),
);

// ─── Order Detail ─────────────────────────────────────────────────────────────

class OrderDetailState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? data;

  const OrderDetailState({
    this.isLoading = false,
    this.error,
    this.data,
  });

  OrderDetailState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? data,
  }) {
    return OrderDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
    );
  }
}

class OrderDetailNotifier extends StateNotifier<OrderDetailState> {
  OrderDetailNotifier(this.bookingId) : super(const OrderDetailState());

  final String bookingId;
  Dio get _client => ApiClient.instance.orderClient;

  Future<void> fetchDetail() async {
    state = const OrderDetailState(isLoading: true);
    try {
      final res = await _client.get(ApiEndpoints.orderDetail(bookingId));
      final body = res.data as Map<String, dynamic>;
      final data = Map<String, dynamic>.from(body['data'] as Map);
      state = OrderDetailState(data: data);
    } on DioException catch (e) {
      state = OrderDetailState(
          error: AppException.fromDioError(e).message);
    } catch (e) {
      state = OrderDetailState(error: e.toString());
    }
  }

  /// Downloads the receipt PDF from the server and saves it to the
  /// device's Downloads folder (Android) or Documents folder (iOS).
  ///
  /// The server returns 404 while the consumer is still generating the
  /// receipt. Retries up to [maxRetries] times with a 2-second pause.
  ///
  /// Returns the saved file path on success, or null on failure.
  Future<String?> downloadReceipt({int maxRetries = 4}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final res = await _client.get(
          ApiEndpoints.receiptDownload(bookingId),
          options: Options(responseType: ResponseType.bytes),
        );

        final bytes = res.data as List<int>;

        // Extract server-provided filename from Content-Disposition header.
        // e.g. attachment; filename="INV-202604-999ADCFA"
        final cd = res.headers['content-disposition']?.first ?? '';
        final fileName = _parseFilename(cd);

        // Resolve the user-visible directory.
        final dir = await _resolveDownloadsDir();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        return file.path;
      } on DioException catch (e) {
        // 404 = receipt not ready yet — retry after 2 s
        if (e.response?.statusCode == 404 && attempt < maxRetries - 1) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
        return null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Parses the filename out of a Content-Disposition header value.
  /// Handles all three quoting styles:
  ///   filename="foo.pdf"   → group 1
  ///   filename='foo.pdf'   → group 2
  ///   filename=foo.pdf     → group 3
  /// Falls back to a name derived from the bookingId.
  String _parseFilename(String contentDisposition) {
    if (contentDisposition.isEmpty) {
      return 'INV-${bookingId.substring(0, 8).toUpperCase()}.pdf';
    }

    final match = RegExp(
      r'''filename\s*=\s*(?:"([^"]+)"|'([^']+)'|([^\s;]+))''',
      caseSensitive: false,
    ).firstMatch(contentDisposition);

    final raw =
        (match?.group(1) ?? match?.group(2) ?? match?.group(3))?.trim();

    if (raw == null || raw.isEmpty) {
      return 'INV-${bookingId.substring(0, 8).toUpperCase()}.pdf';
    }

    return raw.endsWith('.pdf') ? raw : '$raw.pdf';
  }

  /// Returns the best user-accessible directory for saving downloads.
  Future<Directory> _resolveDownloadsDir() async {
    if (Platform.isAndroid) {
      // Prefer the public Downloads folder visible in the Files app.
      try {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) return downloads;
      } catch (_) {}
      // Fallback: app's external storage directory.
      try {
        final ext = await getExternalStorageDirectory();
        if (ext != null) return ext;
      } catch (_) {}
    }
    // iOS: Documents directory (visible via Files app → On My iPhone).
    return getApplicationDocumentsDirectory();
  }

  /// Generates a COD OTP for the given transactionId.
  /// Returns the response data map, or {'error': message} on failure.
  Future<Map<String, dynamic>> generateOtp(String transactionId) async {
    try {
      final res = await _client.post(
        ApiEndpoints.codGenerateOtp,
        data: {'transactionId': transactionId},
      );
      final body = res.data as Map<String, dynamic>;
      return Map<String, dynamic>.from(
          body['data'] as Map? ?? {});
    } on DioException catch (e) {
      return {'error': AppException.fromDioError(e).message};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}

final orderDetailProvider = StateNotifierProvider.autoDispose
    .family<OrderDetailNotifier, OrderDetailState, String>(
  (ref, bookingId) => OrderDetailNotifier(bookingId),
);

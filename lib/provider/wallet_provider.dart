import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

// ─── Models ────────────────────────────────────────────────────────────────────

class WalletBalance {
  final String id;
  final int balancePaise;
  final String balanceRupees;
  final String currency;

  const WalletBalance({
    required this.id,
    required this.balancePaise,
    required this.balanceRupees,
    required this.currency,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) => WalletBalance(
        id: json['id'] as String? ?? '',
        balancePaise: (json['balancePaise'] as num?)?.toInt() ?? 0,
        balanceRupees: json['balanceRupees'] as String? ?? '0.00',
        currency: json['currency'] as String? ?? 'INR',
      );

  double get rupees => balancePaise / 100.0;
}

class WalletTx {
  final String id;
  final int amountPaise;
  final String amountRupees;
  final String type;       // CREDIT | DEBIT
  final String typeLabel;
  final String source;
  final String sourceLabel;
  final String? referenceId;
  final String? description;
  final String? createdAt;

  const WalletTx({
    required this.id,
    required this.amountPaise,
    required this.amountRupees,
    required this.type,
    required this.typeLabel,
    required this.source,
    required this.sourceLabel,
    this.referenceId,
    this.description,
    this.createdAt,
  });

  factory WalletTx.fromJson(Map<String, dynamic> json) => WalletTx(
        id: json['id'] as String? ?? '',
        amountPaise: (json['amountPaise'] as num?)?.toInt() ?? 0,
        amountRupees: json['amountRupees'] as String? ?? '0.00',
        type: json['type'] as String? ?? 'CREDIT',
        typeLabel: json['typeLabel'] as String? ?? '',
        source: json['source'] as String? ?? '',
        sourceLabel: json['sourceLabel'] as String? ?? '',
        referenceId: json['referenceId'] as String?,
        description: json['description'] as String?,
        createdAt: json['createdAt'] as String?,
      );

  bool get isCredit => type == 'CREDIT';
}

// ─── State ─────────────────────────────────────────────────────────────────────

class WalletState {
  final bool isLoadingBalance;
  final bool isLoadingTx;
  final bool isPaying;
  final WalletBalance? balance;
  final List<WalletTx> transactions;
  final bool hasMore;
  final int page;
  final String? error;

  const WalletState({
    this.isLoadingBalance = false,
    this.isLoadingTx = false,
    this.isPaying = false,
    this.balance,
    this.transactions = const [],
    this.hasMore = false,
    this.page = 0,
    this.error,
  });

  WalletState copyWith({
    bool? isLoadingBalance,
    bool? isLoadingTx,
    bool? isPaying,
    WalletBalance? balance,
    List<WalletTx>? transactions,
    bool? hasMore,
    int? page,
    String? error,
    bool clearError = false,
  }) =>
      WalletState(
        isLoadingBalance: isLoadingBalance ?? this.isLoadingBalance,
        isLoadingTx: isLoadingTx ?? this.isLoadingTx,
        isPaying: isPaying ?? this.isPaying,
        balance: balance ?? this.balance,
        transactions: transactions ?? this.transactions,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        error: clearError ? null : error ?? this.error,
      );
}

// ─── Notifier ──────────────────────────────────────────────────────────────────

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier() : super(const WalletState());

  Dio get _client => ApiClient.instance.productClient;

  Future<void> loadBalance() async {
    state = state.copyWith(isLoadingBalance: true, clearError: true);
    try {
      final res = await _client.get(ApiEndpoints.wallet);
      final balance = WalletBalance.fromJson(
          res.data['data'] as Map<String, dynamic>);
      state = state.copyWith(isLoadingBalance: false, balance: balance);
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message'] as String? ??
          'Failed to load wallet.';
      state = state.copyWith(isLoadingBalance: false, error: msg);
    } catch (_) {
      state = state.copyWith(
          isLoadingBalance: false, error: 'Failed to load wallet.');
    }
  }

  Future<void> loadTransactions({bool refresh = false}) async {
    if (state.isLoadingTx) return;
    final nextPage = refresh ? 0 : state.page;
    state = state.copyWith(isLoadingTx: true, clearError: true);
    try {
      final res = await _client.get(
        ApiEndpoints.walletTransactions,
        queryParameters: {'page': nextPage, 'size': 15},
      );
      final data = res.data['data'] as Map<String, dynamic>;
      final items = (data['transactions'] as List<dynamic>)
          .map((e) => WalletTx.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        isLoadingTx: false,
        transactions: refresh ? items : [...state.transactions, ...items],
        hasMore: data['hasMore'] as bool? ?? false,
        page: nextPage + 1,
      );
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message'] as String? ??
          'Failed to load transactions.';
      state = state.copyWith(isLoadingTx: false, error: msg);
    } catch (_) {
      state =
          state.copyWith(isLoadingTx: false, error: 'Failed to load transactions.');
    }
  }

  /// Returns null on success, error message on failure.
  Future<String?> payWithWallet(
      {required String bookingId, required int amountPaise}) async {
    state = state.copyWith(isPaying: true, clearError: true);
    try {
      await _client.post(
        ApiEndpoints.walletPay(bookingId),
        data: {'amountPaise': amountPaise},
      );
      // Refresh balance after payment
      await loadBalance();
      state = state.copyWith(isPaying: false);
      return null;
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message'] as String? ??
          'Payment failed. Please try again.';
      state = state.copyWith(isPaying: false, error: msg);
      return msg;
    } catch (_) {
      const msg = 'Something went wrong. Please try again.';
      state = state.copyWith(isPaying: false, error: msg);
      return msg;
    }
  }
}

// ─── Provider ──────────────────────────────────────────────────────────────────

final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>(
  (ref) => WalletNotifier(),
);

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

// ─── Models ────────────────────────────────────────────────────────────────────

class ChatToken {
  final String sendbirdUserId;
  final String sessionToken;
  // Backend sends expiresAt as epoch-ms int — keep as int, expose as String if needed
  final int? expiresAtMs;

  const ChatToken({
    required this.sendbirdUserId,
    required this.sessionToken,
    this.expiresAtMs,
  });

  factory ChatToken.fromJson(Map<String, dynamic> json) => ChatToken(
        sendbirdUserId: json['sendbirdUserId'] as String,
        sessionToken: json['sessionToken'] as String,
        expiresAtMs: (json['expiresAt'] as num?)?.toInt(),
      );
}

class SupportTicket {
  final String channelUrl;
  final String ticketId;

  const SupportTicket({required this.channelUrl, required this.ticketId});

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        channelUrl: json['channelUrl'] as String,
        ticketId: json['ticketId'] as String,
      );
}

// Issue categories exposed to the UI
class SupportIssue {
  final String key;
  final String label;
  final String emoji;

  const SupportIssue({
    required this.key,
    required this.label,
    required this.emoji,
  });
}

const kSupportIssues = <SupportIssue>[
  SupportIssue(key: 'track_order',     label: 'Track Order',      emoji: '📦'),
  SupportIssue(key: 'cancel_order',    label: 'Cancel Order',     emoji: '❌'),
  SupportIssue(key: 'return_refund',   label: 'Return / Refund',  emoji: '🔄'),
  SupportIssue(key: 'payment_issue',   label: 'Payment Issue',    emoji: '💳'),
  SupportIssue(key: 'delivery_issue',  label: 'Delivery Issue',   emoji: '🚚'),
  SupportIssue(key: 'product_quality', label: 'Product Quality',  emoji: '⭐'),
  SupportIssue(key: 'other',           label: 'Other Issues',     emoji: '💬'),
];

// ─── State ─────────────────────────────────────────────────────────────────────

enum SupportStep { idle, loadingToken, creatingTicket, ready, error }

class SupportState {
  final SupportStep step;
  final String? error;
  final ChatToken? chatToken;
  final SupportTicket? ticket;

  const SupportState({
    this.step = SupportStep.idle,
    this.error,
    this.chatToken,
    this.ticket,
  });

  bool get isLoading =>
      step == SupportStep.loadingToken || step == SupportStep.creatingTicket;

  SupportState copyWith({
    SupportStep? step,
    String? error,
    ChatToken? chatToken,
    SupportTicket? ticket,
  }) =>
      SupportState(
        step: step ?? this.step,
        error: error,
        chatToken: chatToken ?? this.chatToken,
        ticket: ticket ?? this.ticket,
      );
}

// ─── Notifier ──────────────────────────────────────────────────────────────────

class SupportNotifier extends StateNotifier<SupportState> {
  SupportNotifier() : super(const SupportState());

  Dio get _client => ApiClient.instance.chatClient;

  /// Fetches a SendBird session token, then creates (or resumes) a support
  /// channel ticket. Returns the [SupportTicket] on success, null on failure.
  Future<SupportTicket?> startSupportChat({
    required String issue,
    required String category,
    String? orderId,
    String? description,
  }) async {
    state = state.copyWith(step: SupportStep.loadingToken, error: null);
    try {
      // Step 1 — obtain session token
      final tokenRes = await _client.post(ApiEndpoints.chatToken);
      final tokenBody = _unwrap(tokenRes.data);
      final chatToken = ChatToken.fromJson(tokenBody);

      state = state.copyWith(
        step: SupportStep.creatingTicket,
        chatToken: chatToken,
      );

      // Step 2 — create / resume support channel
      final ticketId = orderId != null
          ? '${orderId}_$category'
          : '${category}_${DateTime.now().millisecondsSinceEpoch}';

      final ticketRes = await _client.post(
        ApiEndpoints.chatSupportTicket,
        data: {
          'ticketId': ticketId,
          'issue': description?.isNotEmpty == true ? description : issue,
          'category': category,
          if (orderId != null) 'orderId': orderId,
        },
      );
      final ticketBody = _unwrap(ticketRes.data);
      final ticket = SupportTicket.fromJson(ticketBody);

      state = state.copyWith(step: SupportStep.ready, ticket: ticket);
      return ticket;
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message'] as String? ??
          'Failed to start support chat.';
      state = state.copyWith(step: SupportStep.error, error: msg);
      return null;
    } catch (_) {
      state = state.copyWith(
        step: SupportStep.error,
        error: 'Something went wrong. Please try again.',
      );
      return null;
    }
  }

  void reset() => state = const SupportState();

  // Unwraps { data: {...} } or flat response bodies
  Map<String, dynamic> _unwrap(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body.containsKey('data') && body['data'] is Map) {
        return body['data'] as Map<String, dynamic>;
      }
      return body;
    }
    throw const FormatException('Unexpected response format');
  }
}

// ─── Provider ──────────────────────────────────────────────────────────────────

final supportProvider =
    StateNotifierProvider<SupportNotifier, SupportState>(
  (ref) => SupportNotifier(),
);

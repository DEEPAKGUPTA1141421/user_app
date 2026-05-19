import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

class ZoneState {
  final bool? serviceable; // null = not yet checked
  final bool isChecking;

  const ZoneState({this.serviceable, this.isChecking = false});

  ZoneState copyWith({bool? serviceable, bool? isChecking, bool clearServiceable = false}) =>
      ZoneState(
        serviceable: clearServiceable ? null : (serviceable ?? this.serviceable),
        isChecking: isChecking ?? this.isChecking,
      );
}

class ZoneNotifier extends StateNotifier<ZoneState> {
  ZoneNotifier() : super(const ZoneState());

  Future<void> check(double lat, double lng) async {
    state = const ZoneState(isChecking: true);
    try {
      final resp = await ApiClient.instance.deliveryClient
          .get(ApiEndpoints.zoneCheck(lat, lng));
      final serviceable = resp.data['serviceable'] as bool? ?? false;
      state = ZoneState(serviceable: serviceable);
    } catch (_) {
      // Network or parse error — treat as unknown, don't block user
      state = const ZoneState(serviceable: null);
    }
  }

  void reset() => state = const ZoneState();
}

final zonePod = StateNotifierProvider<ZoneNotifier, ZoneState>(
  (ref) => ZoneNotifier(),
);

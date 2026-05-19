import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';
import '../model/route_stop.dart';
import 'rider_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class RouteState {
  final List<RouteStop> stops;
  final bool isLoading;
  final String? error;
  final bool locationActive;

  const RouteState({
    this.stops = const [],
    this.isLoading = false,
    this.error,
    this.locationActive = false,
  });

  int get totalStops     => stops.length;
  int get completedStops => stops.where((s) => s.status == 'DELIVERED').length;
  int get failedStops    => stops.where((s) => s.status == 'FAILED').length;

  RouteStop? get nextPending => stops
      .where((s) => s.status == 'ASSIGNED' || s.status == 'PICKED')
      .fold<RouteStop?>(null, (best, s) =>
          best == null || s.sequenceNumber < best.sequenceNumber ? s : best);

  RouteState copyWith({
    List<RouteStop>? stops,
    bool? isLoading,
    String? error,
    bool? locationActive,
  }) =>
      RouteState(
        stops: stops ?? this.stops,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        locationActive: locationActive ?? this.locationActive,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class RouteNotifier extends StateNotifier<RouteState> {
  RouteNotifier(this._ref) : super(const RouteState());

  final Ref _ref;
  Dio get _client => ApiClient.instance.deliveryClient;

  Timer? _locationTimer;
  double _lastHeading = 0;
  double _lastSpeed   = 0;

  // ── Fetch today's route ───────────────────────────────────────────────────

  Future<void> fetchTodayRoute() async {
    final riderId = _riderId;
    if (riderId == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.get(ApiEndpoints.riderTodayRoute(riderId));
      final body = res.data as Map<String, dynamic>;
      final list = (body['stops'] as List<dynamic>? ?? [])
          .map((e) => RouteStop.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));
      state = state.copyWith(stops: list, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AppException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Update stop status ────────────────────────────────────────────────────

  Future<bool> updateStatus(
    String assignmentId,
    String newStatus, {
    String? failureReason,
  }) async {
    final riderId = _riderId;
    if (riderId == null) return false;

    try {
      await _client.patch(
        ApiEndpoints.riderAssignmentStatus(riderId, assignmentId),
        data: {
          'status': newStatus,
          if (failureReason != null) 'failureReason': failureReason,
        },
      );

      // Optimistic local update
      final updated = state.stops.map((s) {
        if (s.assignmentId == assignmentId) return s.copyWith(status: newStatus);
        return s;
      }).toList();
      state = state.copyWith(stops: updated);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: AppException.fromDioError(e).message);
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ── Location posting ──────────────────────────────────────────────────────

  Future<void> startLocationPosting() async {
    if (state.locationActive) return;

    final permission = await _ensureLocationPermission();
    if (!permission) return;

    state = state.copyWith(locationActive: true);
    _postLocation(); // immediate first post
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) => _postLocation());
  }

  void stopLocationPosting() {
    _locationTimer?.cancel();
    _locationTimer = null;
    state = state.copyWith(locationActive: false);
  }

  Future<void> _postLocation() async {
    final riderId   = _riderId;
    final warehouseId = _warehouseId;
    if (riderId == null || warehouseId == null) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lastHeading = pos.heading;
      _lastSpeed   = pos.speed * 3.6; // m/s → km/h

      await _client.post(
        ApiEndpoints.riderLocation(riderId),
        data: {
          'lat':         pos.latitude,
          'lng':         pos.longitude,
          'heading':     _lastHeading,
          'speedKmh':    _lastSpeed,
          'warehouseId': warehouseId,
        },
      );
    } catch (_) {
      // Location failures are non-critical — swallow silently
    }
  }

  Future<bool> _ensureLocationPermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }

  String? get _riderId {
    final user = _ref.read(riderPod).user;
    return user['id'] as String? ?? user['riderId'] as String?;
  }

  String? get _warehouseId {
    final user = _ref.read(riderPod).user;
    return user['warehouseId'] as String?;
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final routePod =
    StateNotifierProvider<RouteNotifier, RouteState>((ref) => RouteNotifier(ref));

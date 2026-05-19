import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/rider_provider.dart';
import '../../provider/route_provider.dart';
import '../../utils/app_colors.dart';
import '../../core/widgets/app_loader.dart';
import 'stop_card.dart';

class RiderHomeScreen extends ConsumerStatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  ConsumerState<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends ConsumerState<RiderHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routePod.notifier).fetchTodayRoute();
      ref.read(routePod.notifier).startLocationPosting();
    });
  }

  @override
  void dispose() {
    ref.read(routePod.notifier).stopLocationPosting();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route  = ref.watch(routePod);
    final rider  = ref.watch(riderPod);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.surface,
            pinned: true,
            expandedHeight: 140,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.border),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good ${_greeting()}, ${rider.firstName.isNotEmpty ? rider.firstName : 'Rider'}',
                              style: const TextStyle(
                                  color: AppColors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Today's Route",
                              style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      // Location dot
                      _LocationDot(active: route.locationActive),
                    ]),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
                onPressed: route.isLoading
                    ? null
                    : () => ref.read(routePod.notifier).fetchTodayRoute(),
              ),
            ],
          ),

          // ── Progress banner ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProgressBanner(route: route),
          ),

          // ── Error banner ──────────────────────────────────────────────────
          if (route.error != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(route.error!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12)),
                  ),
                ]),
              ),
            ),

          // ── Loading ───────────────────────────────────────────────────────
          if (route.isLoading && route.stops.isEmpty)
            const SliverFillRemaining(
              child: Center(child: AppSpinner(color: AppColors.green)),
            ),

          // ── Empty state ───────────────────────────────────────────────────
          if (!route.isLoading && route.stops.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.route_rounded,
                          color: AppColors.grey, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text('No stops assigned yet',
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text('The warehouse will assign orders shortly.',
                        style: TextStyle(
                            color: AppColors.grey, fontSize: 13)),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(routePod.notifier).fetchTodayRoute(),
                      icon: const Icon(Icons.refresh_rounded,
                          color: AppColors.white, size: 16),
                      label: const Text('Refresh',
                          style: TextStyle(color: AppColors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Stop list ─────────────────────────────────────────────────────
          if (route.stops.isNotEmpty) ...[
            // Section header: active stops
            _sliverLabel('ACTIVE STOPS'),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final active =
                        route.stops.where((s) => s.isActive).toList();
                    return StopCard(stop: active[i]);
                  },
                  childCount:
                      route.stops.where((s) => s.isActive).length,
                ),
              ),
            ),

            // Section header: completed stops (if any)
            if (route.stops.any((s) => s.isDone)) ...[
              _sliverLabel('COMPLETED'),
              SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final done =
                          route.stops.where((s) => s.isDone).toList();
                      return StopCard(stop: done[i]);
                    },
                    childCount:
                        route.stops.where((s) => s.isDone).length,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sliverLabel(String text) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        sliver: SliverToBoxAdapter(
          child: Text(text,
              style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4)),
        ),
      );

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

// ── Progress banner ───────────────────────────────────────────────────────────

class _ProgressBanner extends StatelessWidget {
  final RouteState route;

  const _ProgressBanner({required this.route});

  @override
  Widget build(BuildContext context) {
    if (route.totalStops == 0) return const SizedBox.shrink();

    final pct = route.totalStops > 0
        ? route.completedStops / route.totalStops
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(
                  value: '${route.completedStops}',
                  label: 'Delivered',
                  color: Colors.greenAccent),
              _Stat(
                  value: '${route.stops.where((s) => s.isActive).length}',
                  label: 'Remaining',
                  color: Colors.amberAccent),
              _Stat(
                  value: '${route.failedStops}',
                  label: 'Failed',
                  color: Colors.redAccent),
              _Stat(
                  value: '${route.totalStops}',
                  label: 'Total',
                  color: AppColors.grey),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.surface2,
              valueColor: const AlwaysStoppedAnimation(Colors.greenAccent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(pct * 100).toStringAsFixed(0)}% complete',
            style: const TextStyle(
                color: AppColors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _Stat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              color: color, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(color: AppColors.grey, fontSize: 11)),
    ]);
  }
}

// ── Location dot ──────────────────────────────────────────────────────────────

class _LocationDot extends StatefulWidget {
  final bool active;

  const _LocationDot({required this.active});

  @override
  State<_LocationDot> createState() => _LocationDotState();
}

class _LocationDotState extends State<_LocationDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.location_off_rounded, size: 12, color: AppColors.grey),
          SizedBox(width: 4),
          Text('GPS off', style: TextStyle(color: AppColors.grey, fontSize: 11)),
        ]),
      );
    }

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withOpacity(0.1 * _pulse.value),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Colors.greenAccent.withOpacity(0.4 * _pulse.value)),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.my_location_rounded, size: 12, color: Colors.greenAccent),
          SizedBox(width: 4),
          Text('Live',
              style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

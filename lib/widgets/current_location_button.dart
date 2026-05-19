import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/rider_provider.dart';
import '../provider/zone_provider.dart';
import '../utils/app_colors.dart';
import '../core/widgets/app_loader.dart';

class CurrentLocationButton extends ConsumerStatefulWidget {
  const CurrentLocationButton({super.key});

  @override
  ConsumerState<CurrentLocationButton> createState() =>
      _CurrentLocationButtonState();
}

class _CurrentLocationButtonState
    extends ConsumerState<CurrentLocationButton> {
  bool isLoading = false;

  Future<void> handleUseCurrentLocation() async {
    setState(() => isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Zone serviceability check before saving
      final zoneNotifier = ref.read(zonePod.notifier);
      await zoneNotifier.check(position.latitude, position.longitude);
      final zoneState = ref.read(zonePod);

      if (zoneState.serviceable == false && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Area Not Serviceable',
                style: TextStyle(
                    color: AppColors.white, fontWeight: FontWeight.bold)),
            content: const Text(
              "We don't deliver to this location yet. You can save it, but checkout will be blocked until we expand coverage.",
              style: TextStyle(color: AppColors.grey, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save Anyway',
                    style: TextStyle(color: AppColors.white)),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }

      final riderNotifier = ref.read(riderPod.notifier);

      final res = await riderNotifier.addAddress(
        position.latitude.toString(),
        position.longitude.toString(),
        true,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['success'] == true
                ? "Location saved successfully"
                : res['message'] ?? "Failed to save",
            style: const TextStyle(color: AppColors.white),
          ),
          backgroundColor: AppColors.surface2,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e",
              style: const TextStyle(color: AppColors.white)),
          backgroundColor: AppColors.surface2,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: isLoading ? null : handleUseCurrentLocation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isLoading
                  ? const AppSpinner(size: 18)
                  : const Icon(
                      CupertinoIcons.location_fill,
                      color: AppColors.white,
                      size: 18,
                    ),
              const SizedBox(width: 10),
              Text(
                isLoading
                    ? "Fetching your location..."
                    : "Use current location",
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
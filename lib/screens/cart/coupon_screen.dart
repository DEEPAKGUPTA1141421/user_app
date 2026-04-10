import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'coupon_card.dart';
import '../../provider/cart_provider.dart';
import '../../utils/app_colors.dart';

class CouponScreen extends ConsumerStatefulWidget {
  const CouponScreen({super.key});

  @override
  ConsumerState<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends ConsumerState<CouponScreen> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch coupons when page opens to show available options
    Future.microtask(() => ref.read(cartProvider.notifier).cartCoupon());
  }

  Future<void> _onRefresh() async {
    await ref.read(cartProvider.notifier).cartCoupon();
  }

  void _handleApplyCoupon(String code) async {
    if (code.isEmpty) {
      await ref.read(cartProvider.notifier).ApplyCartCoupon("");
      if (mounted) {
        final cartState = ref.read(cartProvider);
        final success = cartState['success'] as bool? ?? false;
        final message = cartState['message'] as String? ?? 'Coupon removed from your cart!';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? Colors.redAccent : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Fetch coupons from backend and apply
    await ref.read(cartProvider.notifier).cartCoupon();
    await ref.read(cartProvider.notifier).ApplyCartCoupon(code);
    
    if (mounted) {
      final cartState = ref.read(cartProvider);
      final success = cartState['success'] as bool? ?? false;
      final message = cartState['message'] as String? ?? 'Coupon $code has been applied!';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final isLoading = cartState['isLoading'] as bool? ?? false;
    final bestCoupons = (cartState['bestCoupons'] ?? []) as List<dynamic>;
    final moreCoupons = (cartState['moreCoupons'] ?? []) as List<dynamic>;
    final cartData = (cartState['cartData'] as Map<String, dynamic>?) ?? {};
    final currentappliedCouponOnCart = (cartData['cartCoupon'] as String?) ?? '';
    
    final appliedCoupon = bestCoupons.isEmpty && moreCoupons.isEmpty
        ? <String, dynamic>{}
        : (bestCoupons + moreCoupons).cast<Map<String, dynamic>>().firstWhere(
              (c) => c['code'] == currentappliedCouponOnCart,
              orElse: () => <String, dynamic>{},
            );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildCouponInput(),
              const SizedBox(height: 16),
              if (isLoading) ...[
                const CouponShimmer(),
                const CouponShimmer(),
              ] else ...[
                if (appliedCoupon.isNotEmpty) ...[
                  _buildSectionTitle("Applied Coupon"),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: CouponCard(
                      coupon: appliedCoupon,
                      brandColor: AppColors.white,
                      onApply: _handleApplyCoupon,
                      disable: false,
                      currentappliedCouponOnCart: currentappliedCouponOnCart,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (bestCoupons.isNotEmpty) _buildSectionTitle("Best Coupons"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: bestCoupons
                        .cast<Map<String, dynamic>>()
                        .where((coupon) => (coupon['code'] ?? '') != currentappliedCouponOnCart)
                        .map(
                          (coupon) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CouponCard(
                              coupon: coupon,
                              brandColor: AppColors.white,
                              onApply: _handleApplyCoupon,
                              disable: false,
                              currentappliedCouponOnCart: currentappliedCouponOnCart,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                if (moreCoupons.isNotEmpty) _buildSectionTitle("More Offers"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: moreCoupons
                        .cast<Map<String, dynamic>>()
                        .map(
                          (coupon) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CouponCard(
                              coupon: coupon,
                              brandColor: AppColors.white,
                              onApply: _handleApplyCoupon,
                              disable: true,
                              currentappliedCouponOnCart: currentappliedCouponOnCart,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (bestCoupons.isEmpty && moreCoupons.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      "No coupons available",
                      style: TextStyle(color: AppColors.grey),
                    ),
                  ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "APPLY COUPON",
                  style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Get amazing discounts!",
                  style: TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _couponController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.normal),
              decoration: InputDecoration(
                hintText: "Enter Coupon Code",
                hintStyle: const TextStyle(color: AppColors.grey, fontWeight: FontWeight.normal),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.white, width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              if (_couponController.text.isNotEmpty) {
                _handleApplyCoupon(_couponController.text);
                _couponController.clear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              "APPLY",
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.bg),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.white),
        ),
      ),
    );
  }
}

class CouponShimmer extends StatelessWidget {
  const CouponShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surface2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

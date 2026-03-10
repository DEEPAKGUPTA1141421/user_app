import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'coupon_card.dart';
import '../../provider/cart_provider.dart';
import './order_summary_page.dart';
class CouponScreen extends ConsumerStatefulWidget {
  const CouponScreen({super.key});

  @override
  ConsumerState<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends ConsumerState<CouponScreen> {
  final TextEditingController _couponController = TextEditingController();

  Future<void> _onRefresh() async {
    await ref.read(cartProvider.notifier).cartCoupon();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(cartProvider.notifier).cartCoupon());
  }

  void _handleApplyCoupon(String code) async {
    // ✅ If empty string passed, treat as remove
    if (code.isEmpty) {
      //ref.watch(cartProvider.notifier).removeItem(itemId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Coupon removed from your cart!"),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );

      return;
    }

    // ✅ Apply coupon flow
    ref.watch(cartProvider.notifier).ApplyCartCoupon(code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Coupon $code has been applied to your cart!"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    if (mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrderSummaryPage()),
    );
  }
  }

  @override
  Widget build(BuildContext context) {
    final Color brandColor = Colors.deepOrange;
    final cartState = ref.watch(cartProvider);
    final isLoading = cartState['isLoading'] as bool? ?? false;
    final bestCoupons = (cartState['bestCoupons'] ?? []) as List<dynamic>;
    final moreCoupons = (cartState['moreCoupons'] ?? []) as List<dynamic>;
    final currentappliedCouponOnCart = cartState['cartData']['cartCoupon'];
    final appliedCoupon = (bestCoupons + moreCoupons).firstWhere(
      (c) => c['code'] == currentappliedCouponOnCart,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: brandColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Column(
              children: [
                _buildHeader(brandColor),
                const SizedBox(height: 16),

                // Coupon Input
                _buildCouponInput(brandColor),

                const SizedBox(height: 16),

                if (isLoading) ...[
                  const CouponShimmer(),
                  const CouponShimmer(),
                ] else ...[
                  // ✅ Applied Coupon Section
                  if (appliedCoupon != null) ...[
                    _buildSectionTitle("Applied Coupon"),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CouponCard(
                        coupon: appliedCoupon,
                        brandColor: brandColor,
                        onApply: _handleApplyCoupon,
                        disable: false,
                        currentappliedCouponOnCart: currentappliedCouponOnCart,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ✅ Best Coupon Section
                  if (bestCoupons.isNotEmpty) _buildSectionTitle("Best Coupons"),
...bestCoupons
    .where((coupon) => coupon['code'] != currentappliedCouponOnCart) // exclude applied coupon
    .map(
      (coupon) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CouponCard(
          coupon: coupon,
          brandColor: brandColor,
          onApply: _handleApplyCoupon,
          disable: false,
          currentappliedCouponOnCart: currentappliedCouponOnCart,
        ),
      ),
    ),


                  const SizedBox(height: 16),

                  // ✅ More Offers Section
                  if (moreCoupons.isNotEmpty) _buildSectionTitle("More Offers"),
                  ...moreCoupons.map(
                    (coupon) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CouponCard(
                        coupon: coupon,
                        brandColor: brandColor,
                        onApply: _handleApplyCoupon,
                        disable: true,
                        currentappliedCouponOnCart: currentappliedCouponOnCart,
                      ),
                    ),
                  ),

                  if (bestCoupons.isEmpty && moreCoupons.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text(
                        "No coupons available currently",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),

      // ✅ Bottom Button (unchanged)
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader(Color brandColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "APPLY COUPON",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "Your cart: ₹219",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCouponInput(Color brandColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _couponController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: "Enter Coupon Code",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _handleApplyCoupon(_couponController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "APPLY",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.all(12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {},
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("🎯 ", style: TextStyle(fontSize: 18)),
            Text("View Add-On Payment Offers",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Spacer(),
            Text("↓", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

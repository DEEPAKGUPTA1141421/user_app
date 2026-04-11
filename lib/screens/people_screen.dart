import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/screens/auth/login_screen.dart';
import 'package:user_app/utils/StorageService.dart';
import '../provider/rider_provider.dart';
import '../utils/app_colors.dart';
import '../core/widgets/app_loader.dart';
class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(riderPod.notifier).getUserDetail());
  }

  Future<void> handleLogout() async {
    await StorageService.clearTokens();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(riderPod);
    final isLoading = state.isLoading;
    final name      = state.fullName;
    final phone     = state.phone;
    final avatarUrl = state.avatarUrl;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppRefreshIndicator(
        onRefresh: () async {
          await ref.read(riderPod.notifier).getUserDetail();
        },
        child: CustomScrollView(
          slivers: [

          // 🔹 Header (same style as EditProfile)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              child: Row(
                children: [
                  _avatar(avatarUrl, name, isLoading),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : 'Your Name',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phone.isNotEmpty ? '+91 $phone' : '',
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.white),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/account/profile'),
                  )
                ],
              ),
            ),
          ),

          // divider
          SliverToBoxAdapter(child: Container(height: 1, color: AppColors.divider)),

          // 🔹 Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
                children: [
                  _quickItem(Icons.shopping_bag_outlined, "Orders", "/account/orders"),
                  _quickItem(Icons.favorite_border, "Wishlist", "/account/wishlist"),
                  _quickItem(Icons.support_agent_outlined, "Support", "/account/support"),
                  _quickItem(Icons.location_on_outlined, "Addresses", "/account/addresses"),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: Container(height: 1, color: AppColors.divider)),

          // 🔹 Menu sections
          SliverToBoxAdapter(child: _menuSection("ACCOUNT", [
            _menuItem(Icons.person_outline, "Edit Profile", "/account/profile"),
            _menuItem(Icons.credit_card_outlined, "Saved Cards", "/account/cards"),
            _menuItem(Icons.location_on_outlined, "Saved Addresses", "/account/addresses"),
            _menuItem(Icons.notifications_outlined, "Notifications", "/account/notifications"),
          ])),

          SliverToBoxAdapter(child: _menuSection("ACTIVITY", [
            _menuItem(Icons.star_border, "My Reviews", "/account/reviews"),
          ])),

          SliverToBoxAdapter(child: _menuSection("INFO", [
            _menuItem(Icons.description_outlined, "Terms & Policies", "/account/terms"),
            _menuItem(Icons.help_outline, "FAQs", "/account/faqs"),
          ])),

          // 🔹 Logout
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: handleLogout,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      "Log Out",
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
        ),
      ),
    );
  }

  // 🔹 Avatar widget
  Widget _avatar(String? url, String name, bool loading) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 1.5),
      ),
      child: ClipOval(
        child: loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.white))
            : url != null
                ? Image.network(url, fit: BoxFit.cover)
                : Center(
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
      ),
    );
  }

  // 🔹 Quick item
  Widget _quickItem(IconData icon, String label, String path) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, path),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.white, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: AppColors.grey, fontSize: 12),
          )
        ],
      ),
    );
  }

  // 🔹 Menu Section
  Widget _menuSection(String title, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              )),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, String path) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, path),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.grey, size: 18),
            const SizedBox(width: 16),
            Text(label,
                style: const TextStyle(color: AppColors.white, fontSize: 14)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.greyDark, size: 18),
          ],
        ),
      ),
    );
  }
}
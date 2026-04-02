import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/screens/auth/login_screen.dart';
import 'package:user_app/utils/StorageService.dart';
import '../provider/rider_provider.dart';

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  static const brandColor = Colors.black;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(riderPod.notifier).getUserDetail());
  }

  Future<void> handleLogout() async {
    await StorageService.deleteToken();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final riderState = ref.watch(riderPod);
    final isLoading = riderState['isLoading'] ?? false;
    final userDetail = riderState['user_detail'] ?? {};
    final name = userDetail['name'] ?? '';
    final phone = userDetail['phone'] ?? '';
    final avatarUrl = userDetail['avatarUrl'];

    final quickAccess = [
      {"label": "My Orders", "icon": Icons.shopping_bag_outlined, "path": "/account/orders"},
      {"label": "Wishlist", "icon": Icons.favorite_border, "path": "/account/wishlist"},
      {"label": "Support", "icon": Icons.support_agent_outlined, "path": "/account/support"},
      {"label": "Addresses", "icon": Icons.location_on_outlined, "path": "/account/addresses"},
    ];

    final settingsMenu = [
      {"icon": Icons.person_outline, "label": "Edit Profile", "path": "/account/profile"},
      {"icon": Icons.credit_card_outlined, "label": "Saved Cards & UPI", "path": "/account/cards"},
      {"icon": Icons.location_on_outlined, "label": "Saved Addresses", "path": "/account/addresses"},
      {"icon": Icons.notifications_outlined, "label": "Notification Settings", "path": "/account/notifications"},
      {"icon": Icons.privacy_tip_outlined, "label": "Privacy Center", "path": "/account/privacy"},
    ];

    final activityMenu = [
      {"icon": Icons.star_border, "label": "My Reviews", "path": "/account/reviews"},
      {"icon": Icons.quiz_outlined, "label": "Questions & Answers", "path": "/account/qa"},
    ];

    final infoMenu = [
      {"icon": Icons.description_outlined, "label": "Terms & Policies", "path": "/account/terms"},
      {"icon": Icons.help_outline, "label": "Browse FAQs", "path": "/account/faqs"},
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          // Header with profile
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: isLoading
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(height: 18, width: 120, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(4))),
                              const SizedBox(height: 6),
                              Container(height: 14, width: 90, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isNotEmpty ? name : 'Hello there!',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (phone.isNotEmpty)
                                Text(
                                  '+91 $phone',
                                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                                ),
                            ],
                          ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () => Navigator.pushNamed(context, '/account/profile'),
                  ),
                ],
              ),
            ),
          ),

          // Quick Access Grid
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quickAccess.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final item = quickAccess[index];
                  return InkWell(
                    onTap: () => Navigator.pushNamed(context, item["path"] as String),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: brandColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item["icon"] as IconData, color: brandColor, size: 22),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item["label"].toString(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Settings
          SliverToBoxAdapter(
            child: _buildMenuSection(context, "Account Settings", settingsMenu),
          ),
          SliverToBoxAdapter(
            child: _buildMenuSection(context, "My Activity", activityMenu),
          ),
          SliverToBoxAdapter(
            child: _buildMenuSection(context, "Help & Info", infoMenu),
          ),

          // Logout
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: handleLogout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text("Log Out"),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: brandColor),
                    foregroundColor: brandColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, String title, List<Map<String, dynamic>> items) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...items.map((item) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: Icon(item["icon"] as IconData, color: const Color(0xFF444444), size: 22),
                title: Text(item["label"] as String, style: const TextStyle(fontSize: 14)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                dense: true,
                onTap: () => Navigator.pushNamed(context, item["path"] as String),
              )),
        ],
      ),
    );
  }
}
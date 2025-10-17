import 'package:flutter/material.dart';
import 'package:user_app/screens/auth/login_screen.dart';
import 'package:user_app/utils/StorageService.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFFF5200);

    final quickAccess = [
      {"label": "My Account", "icon": Icons.person, "path": "/account"},
      {
        "label": "My Orders",
        "icon": Icons.shopping_bag,
        "path": "/account/orders"
      },
      {
        "label": "Wishlist & Collections",
        "icon": Icons.favorite_border,
        "path": "/account/wishlist"
      },
      {
        "label": "Customer Support",
        "icon": Icons.support_agent,
        "path": "/account/support"
      },
    ];

    final accountSections = [
      {
        "title": "Recently Viewed Stores",
        "items": [
          {"name": "Mobiles", "image": "📱"},
          {"name": "Women's T...", "image": "👚"},
          {"name": "Women's K...", "image": "👗"},
          {"name": "Home", "image": "🏠"},
        ]
      }
    ];

    final languages = [
      {"code": "hi", "name": "हिंदी"},
      {"code": "ta", "name": "தமிழ்"},
      {"code": "te", "name": "తెలుగు"},
      {"code": "kn", "name": "ಕನ್ನಡ"},
    ];

    final settingsMenu = [
      {"icon": Icons.star, "label": "Flipkart Plus", "path": "/account/plus"},
      {
        "icon": Icons.person,
        "label": "Edit Profile",
        "path": "/account/profile"
      },
      {
        "icon": Icons.credit_card,
        "label": "Saved Credit / Debit & Gift Cards",
        "path": "/account/cards"
      },
      {
        "icon": Icons.location_on,
        "label": "Saved Addresses",
        "path": "/account/addresses"
      },
      {
        "icon": Icons.language,
        "label": "Select Language",
        "path": "/account/language"
      },
      {
        "icon": Icons.notifications,
        "label": "Notification Settings",
        "path": "/account/notifications"
      },
      {
        "icon": Icons.privacy_tip,
        "label": "Privacy Center",
        "path": "/account/privacy"
      },
    ];

    final activityMenu = [
      {"icon": Icons.edit, "label": "Reviews", "path": "/account/reviews"},
      {
        "icon": Icons.question_answer,
        "label": "Questions & Answers",
        "path": "/account/qa"
      },
    ];

    final earnMenu = [
      {
        "icon": Icons.store,
        "label": "Sell on Flipkart",
        "path": "/account/sell"
      },
    ];

    final infoMenu = [
      {
        "icon": Icons.description,
        "label": "Terms, Policies and Licenses",
        "path": "/account/terms"
      },
      {
        "icon": Icons.help_outline,
        "label": "Browse FAQs",
        "path": "/account/faqs"
      },
    ];
    Future<void> handleLogout(BuildContext context) async {
      await StorageService.deleteToken();
      //  → go to Login
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        title: const Text("Account", style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 👇 New Quick Access Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quickAccess.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3.5,
                ),
                itemBuilder: (context, index) {
                  final item = quickAccess[index];
                  return InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, item["path"] as String);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: brandColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: brandColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item["icon"] as IconData, color: brandColor),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              item["label"].toString(),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Recently Viewed Stores
            _buildSection(
              title: accountSections[0]["title"].toString(),
              child: SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: (accountSections[0]["items"] as List).length,
                  itemBuilder: (context, index) {
                    final item = (accountSections[0]["items"] as List)[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(item["image"],
                                style: const TextStyle(fontSize: 30)),
                          ),
                          const SizedBox(height: 8),
                          Text(item["name"],
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Try Flipkart in your language
            _buildSection(
              title: "Try Flipkart in your language",
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...languages.map((lang) {
                    return OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(lang["name"].toString(),
                          style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  TextButton(
                    onPressed: () {},
                    child: const Text("+8 more",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w600)),
                  )
                ],
              ),
            ),

            // Menus
            _buildMenuSection(
                context, "Account Settings", settingsMenu, brandColor),
            _buildMenuSection(context, "My Activity", activityMenu, brandColor),
            _buildMenuSection(
                context, "Earn with Flipkart", earnMenu, brandColor),
            _buildMenuSection(
                context, "Feedback & Information", infoMenu, brandColor),

            // Logout Button
            Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    handleLogout(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: brandColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    "Log Out",
                    style: TextStyle(
                        color: brandColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF5200))),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, String title,
      List<Map<String, dynamic>> items, Color brandColor) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...items.map((item) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(item["icon"], color: brandColor),
              title: Text(item["label"]),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.pushNamed(context, item["path"]);
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}

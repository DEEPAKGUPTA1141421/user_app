import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const brandColor = Color(0xFFFF5200);

  String selectedAvatar = "male";

  final TextEditingController firstNameController =
      TextEditingController(text: "Deepak kumar");
  final TextEditingController lastNameController =
      TextEditingController(text: "Gupta");
  final TextEditingController mobileController =
      TextEditingController(text: "+919608557095");
  final TextEditingController emailController =
      TextEditingController(text: "himanshkumargupta288@gmail.com");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: brandColor,
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          children: [
            // Avatar Section
            Container(
              color: brandColor,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      avatarButton("male", "👨"),
                      const SizedBox(width: 20),
                      const Text("or",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 16)),
                      const SizedBox(width: 20),
                      avatarButton("female", "👩"),
                    ],
                  ),
                  Positioned(
                    bottom: 0,
                    right: 10,
                    child: FloatingActionButton.small(
                      backgroundColor: Colors.white,
                      onPressed: () {},
                      child: Icon(Icons.edit, color: brandColor, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Form Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // First Name
                  buildTextField(
                    label: "First Name",
                    controller: firstNameController,
                    enabled: true,
                  ),
                  const SizedBox(height: 20),

                  // Last Name
                  buildTextField(
                    label: "Last Name",
                    controller: lastNameController,
                    enabled: true,
                  ),
                  const SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {},
                      child: const Text(
                        "SUBMIT",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Mobile Section
                  buildReadOnlyField(
                    label: "Mobile Number",
                    controller: mobileController,
                    actionLabel: "Update",
                  ),
                  const SizedBox(height: 20),

                  // Email Section
                  buildReadOnlyField(
                    label: "Email ID",
                    controller: emailController,
                    actionLabel: "Verify",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget avatarButton(String gender, String emoji) {
    final bool isSelected = selectedAvatar == gender;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAvatar = gender;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 4)
              : Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.white.withOpacity(0.4), blurRadius: 10)
                ]
              : [],
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 42),
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.only(top: 8, bottom: 4),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey)),
            focusedBorder:
                UnderlineInputBorder(borderSide: BorderSide(color: brandColor)),
          ),
        ),
      ],
    );
  }

  Widget buildReadOnlyField({
    required String label,
    required TextEditingController controller,
    required String actionLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            TextButton(
              onPressed: () {},
              child: Text(actionLabel,
                  style: TextStyle(color: brandColor, fontSize: 13)),
            ),
          ],
        ),
        TextField(
          controller: controller,
          enabled: false,
          decoration: const InputDecoration(
            disabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey)),
          ),
        ),
      ],
    );
  }
}

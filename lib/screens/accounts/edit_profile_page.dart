import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../provider/rider_provider.dart';
import '../../utils/StorageService.dart';
import '../../constant/ServerApi.dart';
import '../../utils/app_colors.dart';

// ─── Page ─────────────────────────────────────────────────────────────────────
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage>
    with TickerProviderStateMixin {

  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _otpCtrl       = TextEditingController();

  String?   _gender;
  DateTime? _dob;

  bool _otpSent      = false;
  bool _emailLoading = false;
  bool _saving       = false;

  File? _avatarFile;
  bool  _avatarLoading = false;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    Future.microtask(() async {
      await ref.read(riderPod.notifier).getUserDetail();
      _loadFromState();
    });
  }

  void _loadFromState() {
  final ud = ref.read(riderPod)['user_detail'] ?? {};

  _firstNameCtrl.text = ud['firstName'] ?? '';
  _lastNameCtrl.text  = ud['lastName'] ?? '';
  _emailCtrl.text     = ud['email'] ?? '';
  _gender             = ud['gender'];

  if (ud['dateOfBirth'] != null) {
    try {
      _dob = DateTime.parse(ud['dateOfBirth']);
    } catch (_) {}
  }

  setState(() {});
}

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  // ─── Avatar ──────────────────────────────────────────────────────────────
  Future<void> _pickAvatar() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          _sheetOption(Icons.camera_alt_outlined, 'Take Photo',
              () => Navigator.pop(context, ImageSource.camera)),
          _sheetOption(Icons.photo_library_outlined, 'Choose from Library',
              () => Navigator.pop(context, ImageSource.gallery)),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (src == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: src, imageQuality: 80);
    if (picked == null) return;

    setState(() {
      _avatarFile    = File(picked.path);
      _avatarLoading = true;
    });

    final token = await StorageService.getAccessToken();
    final req   = http.MultipartRequest(
        'PATCH',
        Uri.parse('${ServerApi.productClientService}/api/v1/user/profile/avatar'));
    req.headers['Authorization'] = 'Bearer $token';
    req.files.add(await http.MultipartFile.fromPath('file', picked.path));

    try {
      final res = await req.send();
      if (res.statusCode == 200) {
        _toast('Avatar updated!', success: true);
        await ref.read(riderPod.notifier).getUserDetail();
      } else {
        _toast('Upload failed', success: false);
      }
    } catch (_) {
      _toast('Upload failed', success: false);
    } finally {
      setState(() => _avatarLoading = false);
    }
  }

  // ─── Save personal ────────────────────────────────────────────────────────
  Future<void> _savePersonal() async {
    if (_firstNameCtrl.text.trim().isEmpty) {
      _toast('First name required', success: false);
      return;
    }
    setState(() => _saving = true);
    final token = await StorageService.getAccessToken();
    final body  = <String, dynamic>{
      'firstName': _firstNameCtrl.text.trim(),
      'lastName':  _lastNameCtrl.text.trim(),
    };
    if (_gender != null) body['gender']      = _gender;
    if (_dob    != null) body['dateOfBirth'] = _dob!.toIso8601String();

    try {
      final res = await http.put(
        Uri.parse('${ServerApi.productClientService}/api/v1/user/profile'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        _toast('Profile saved!', success: true);
        await ref.read(riderPod.notifier).getUserDetail();
      } else {
        _toast('Update failed', success: false);
      }
    } catch (_) {
      _toast('Something went wrong', success: false);
    } finally {
      setState(() => _saving = false);
    }
  }

  // ─── Email OTP ────────────────────────────────────────────────────────────
  Future<void> _requestEmailOtp() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) {
      _toast('Enter a valid email', success: false);
      return;
    }
    setState(() => _emailLoading = true);
    final token = await StorageService.getAccessToken();
    try {
      final res = await http.post(
        Uri.parse('${ServerApi.productClientService}/api/v1/user/verify-email/request'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': email}),
      );
      final b = jsonDecode(res.body);
      if (b['success'] == true) {
        setState(() => _otpSent = true);
        _toast('OTP sent to $email', success: true);
      } else {
        _toast(b['message'] ?? 'Failed', success: false);
      }
    } catch (_) {
      _toast('Something went wrong', success: false);
    } finally {
      setState(() => _emailLoading = false);
    }
  }

  Future<void> _verifyEmailOtp() async {
    if (_otpCtrl.text.length != 6) {
      _toast('Enter 6-digit OTP', success: false);
      return;
    }
    setState(() => _emailLoading = true);
    final token = await StorageService.getAccessToken();
    try {
      final res = await http.post(
        Uri.parse('${ServerApi.productClientService}/api/v1/user/verify-email/confirm'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'otp': _otpCtrl.text}),
      );
      final b = jsonDecode(res.body);
      if (b['success'] == true) {
        setState(() { _otpSent = false; _otpCtrl.clear(); });
        _toast('Email updated!', success: true);
        await ref.read(riderPod.notifier).getUserDetail();
      } else {
        _toast(b['message'] ?? 'Invalid OTP', success: false);
      }
    } catch (_) {
      _toast('Something went wrong', success: false);
    } finally {
      setState(() => _emailLoading = false);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  void _toast(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(color: AppColors.white, fontSize: 14)),
      backgroundColor: AppColors.surface2,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
              color: success ? Colors.white54 : Colors.white24, width: 1)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  Widget _sheetOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(children: [
          Icon(icon, color: AppColors.white, size: 22),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(
              color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state         = ref.watch(riderPod);
    final ud            = state['user_detail'] ?? {};
    final isLoading     = state['isLoading'] as bool? ?? false;
    final name =  '${ud['firstName'] ?? ''} ${ud['lastName'] ?? ''}'.trim();
    final phone         = ud['phone']     ?? '';
    final avatarUrl     = ud['avatarUrl'] as String?;
    final emailVerified = ud['emailVerified'] as bool? ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ───────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Edit Profile',
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3)),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.white, strokeWidth: 2))
                      : GestureDetector(
                          onTap: _savePersonal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Save',
                                style: TextStyle(
                                    color: AppColors.bg,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: AppColors.divider),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar ────────────────────────────────────────────
                  _AvatarHeader(
                    avatarFile:    _avatarFile,
                    avatarUrl:     avatarUrl,
                    name:          name,
                    phone:         phone,
                    loading:       _avatarLoading || isLoading,
                    onTap:         _pickAvatar,
                  ),

                  // thin divider
                  Container(height: 1, color: AppColors.divider),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Personal ─────────────────────────────────────
                        _Label('PERSONAL INFO'),
                        const SizedBox(height: 16),
                        _Field(
                          label:      'First name',
                          controller: _firstNameCtrl,
                          hint:       'Enter first name',
                          icon:       Icons.person_outline,
                        ),
                        const SizedBox(height: 14),
                        _Field(
                          label:      'Last name',
                          controller: _lastNameCtrl,
                          hint:       'Enter last name',
                          icon:       Icons.person_outline,
                        ),

                        const SizedBox(height: 28),

                        // ── Gender ────────────────────────────────────────
                        _Label('GENDER'),
                        const SizedBox(height: 12),
                        _GenderSelector(
                          current:   _gender,
                          onChanged: (g) => setState(() => _gender = g),
                        ),

                        const SizedBox(height: 28),

                        // ── DOB ───────────────────────────────────────────
                        _Label('DATE OF BIRTH'),
                        const SizedBox(height: 12),
                        _DobPicker(
                          value:     _dob,
                          onChanged: (d) => setState(() => _dob = d),
                        ),

                        const SizedBox(height: 32),

                        // thin divider
                        Container(height: 1, color: AppColors.divider),

                        const SizedBox(height: 32),

                        // ── Email ─────────────────────────────────────────
                        _Label('PHONE NUMBER'),
                        const SizedBox(height: 16),

                        // Phone read-only strip
                        _ReadOnlyStrip(
                          icon:  Icons.phone_outlined,
                          value: phone.isNotEmpty ? '+91 $phone' : 'No phone',
                          note:  'Primary login — cannot be changed',
                        ),

                        const SizedBox(height: 20),

                        _Field(
                          label:        'Email',
                          controller:   _emailCtrl,
                          hint:         'your@email.com',
                          icon:         Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          suffix: emailVerified
                              ? const Icon(Icons.check_circle_outline,
                                  color: AppColors.white, size: 18)
                              : null,
                        ),

                        if (emailVerified) ...[
                          const SizedBox(height: 6),
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text('Verified',
                                style: TextStyle(
                                    color: AppColors.grey, fontSize: 12)),
                          ),
                        ],

                        const SizedBox(height: 16),

                        if (!_otpSent)
                          _OutlineButton(
                            label:   'Send Verification OTP',
                            loading: _emailLoading,
                            onTap:   _requestEmailOtp,
                          )
                        else ...[
                          _Field(
                            label:        'Verification code',
                            controller:   _otpCtrl,
                            hint:         '6-digit OTP',
                            icon:         Icons.lock_outline,
                            keyboardType: TextInputType.number,
                            maxLength:    6,
                          ),
                          const SizedBox(height: 14),
                          Row(children: [
                            Expanded(
                              child: _FilledButton(
                                label:   'Verify & Update',
                                loading: _emailLoading,
                                onTap:   _verifyEmailOtp,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => setState(() {
                                _otpSent = false;
                                _otpCtrl.clear();
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 14),
                                decoration: BoxDecoration(
                                  color:  AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Text('Cancel',
                                    style: TextStyle(
                                        color: AppColors.grey, fontSize: 14)),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text('OTP sent to ${_emailCtrl.text}',
                                style: const TextStyle(
                                    color: AppColors.grey, fontSize: 12)),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar header ────────────────────────────────────────────────────────────
class _AvatarHeader extends StatelessWidget {
  final File?      avatarFile;
  final String?    avatarUrl;
  final String     name;
  final String     phone;
  final bool       loading;
  final VoidCallback onTap;

  const _AvatarHeader({
    required this.avatarFile,
    required this.avatarUrl,
    required this.name,
    required this.phone,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        color: AppColors.bg,
        child: Row(children: [
          // Avatar circle
          Stack(children: [
            Container(
              width: 76, height: 76,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
              child: ClipOval(
                child: loading
                    ? Container(
                        color: AppColors.surface2,
                        child: const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.white, strokeWidth: 2)))
                    : avatarFile != null
                        ? Image.file(avatarFile!, fit: BoxFit.cover)
                        : avatarUrl != null
                            ? Image.network(avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _initials(name))
                            : _initials(name),
              ),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color:  AppColors.white,
                  shape:  BoxShape.circle,
                  border: Border.all(color: AppColors.bg, width: 2),
                ),
                child: const Icon(Icons.camera_alt,
                    size: 12, color: AppColors.bg),
              ),
            ),
          ]),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Your Name',
                  style: const TextStyle(
                      color:       AppColors.white,
                      fontSize:    20,
                      fontWeight:  FontWeight.w700,
                      letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  phone.isNotEmpty ? '+91 $phone' : '—',
                  style: const TextStyle(color: AppColors.grey, fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.edit_outlined, size: 12, color: AppColors.grey),
                  SizedBox(width: 4),
                  Text('Change photo',
                      style: TextStyle(color: AppColors.grey, fontSize: 12)),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _initials(String n) => Container(
    color:     AppColors.surface2,
    alignment: Alignment.center,
    child: Text(
      n.isNotEmpty ? n[0].toUpperCase() : '?',
      style: const TextStyle(
          color: AppColors.white, fontSize: 28, fontWeight: FontWeight.bold),
    ),
  );
}

// ─── Gender selector ──────────────────────────────────────────────────────────
class _GenderSelector extends StatelessWidget {
  final String?              current;
  final ValueChanged<String?> onChanged;

  const _GenderSelector({required this.current, required this.onChanged});

  static const _opts = [
    ('MALE',              'Male'),
    ('FEMALE',            'Female'),
    ('OTHER',             'Other'),
    ('PREFER_NOT_TO_SAY', 'Prefer not to say'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _opts.map((o) {
        final sel = current == o.$1;
        return GestureDetector(
          onTap: () => onChanged(sel ? null : o.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color:  sel ? AppColors.white : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: sel ? AppColors.white : AppColors.border, width: 1.5),
            ),
            child: Text(o.$2,
                style: TextStyle(
                    color:      sel ? AppColors.bg : AppColors.grey,
                    fontSize:   13,
                    fontWeight: sel
                        ? FontWeight.w700
                        : FontWeight.w400)),
          ),
        );
      }).toList(),
    );
  }
}

// ─── DOB picker ───────────────────────────────────────────────────────────────
class _DobPicker extends StatelessWidget {
  final DateTime?              value;
  final ValueChanged<DateTime?> onChanged;

  const _DobPicker({required this.value, required this.onChanged});

  String _fmt(DateTime? d) {
    if (d == null) return 'Select date of birth';
    return '${d.day.toString().padLeft(2, '0')} / '
        '${d.month.toString().padLeft(2, '0')} / ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final p = await showDatePicker(
          context:     context,
          initialDate: value ??
              DateTime.now().subtract(const Duration(days: 365 * 18)),
          firstDate: DateTime(1940),
          lastDate:  DateTime.now().subtract(const Duration(days: 365 * 10)),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary:   AppColors.white,
                onPrimary: AppColors.bg,
                surface:   Color(0xFF1A1A1A),
                onSurface: AppColors.white,
              ),
              dialogBackgroundColor: AppColors.surface,
            ),
            child: child!,
          ),
        );
        if (p != null) onChanged(p);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:  AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: value != null ? Colors.white38 : AppColors.border),
        ),
        child: Row(children: [
          Icon(Icons.cake_outlined,
              size: 18,
              color: value != null ? AppColors.white : AppColors.grey),
          const SizedBox(width: 12),
          Text(_fmt(value),
              style: TextStyle(
                  color:   value != null ? AppColors.white : AppColors.grey,
                  fontSize: 15)),
          const Spacer(),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.greyDark),
        ]),
      ),
    );
  }
}

// ─── Read-only strip ──────────────────────────────────────────────────────────
class _ReadOnlyStrip extends StatelessWidget {
  final IconData icon;
  final String   value;
  final String   note;

  const _ReadOnlyStrip({
    required this.icon,
    required this.value,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:  AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.grey, size: 18),
          const SizedBox(width: 12),
          Text(value,
              style: const TextStyle(color: AppColors.white, fontSize: 15)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Locked',
                style: TextStyle(color: AppColors.greyDark, fontSize: 11)),
          ),
        ]),
      ),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(note,
            style: const TextStyle(color: AppColors.greyDark, fontSize: 11)),
      ),
    ]);
  }
}

// ─── Shared field ─────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final String                  label;
  final TextEditingController   controller;
  final String                  hint;
  final IconData                icon;
  final TextInputType           keyboardType;
  final int?                    maxLength;
  final Widget?                 suffix;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label.isNotEmpty) ...[
        Text(label,
            style: const TextStyle(
                color:      AppColors.grey,
                fontSize:    11,
                fontWeight:  FontWeight.w500,
                letterSpacing: 0.4)),
        const SizedBox(height: 8),
      ],
      TextFormField(
        controller:   controller,
        keyboardType: keyboardType,
        maxLength:    maxLength,
        style: const TextStyle(color: AppColors.white, fontSize: 15),
        cursorColor: AppColors.white,
        decoration: InputDecoration(
          hintText:  hint,
          hintStyle: const TextStyle(color: AppColors.greyDark, fontSize: 15),
          prefixIcon: Icon(icon, color: AppColors.grey, size: 18),
          suffixIcon: suffix,
          filled:      true,
          fillColor:   AppColors.surface,
          counterText: '',
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.white, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    ]);
  }
}

// ─── Filled button (white bg, black text) ────────────────────────────────────
class _FilledButton extends StatelessWidget {
  final String     label;
  final bool       loading;
  final VoidCallback onTap;

  const _FilledButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:  loading ? AppColors.surface2 : AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: AppColors.white, strokeWidth: 2))
              : Text(label,
                  style: const TextStyle(
                      color:      AppColors.white,
                      fontSize:   14,
                      fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

// ─── Outline button (transparent bg, white border) ────────────────────────────
class _OutlineButton extends StatelessWidget {
  final String       label;
  final bool         loading;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: loading ? AppColors.border : AppColors.white, width: 1.5),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: AppColors.white, strokeWidth: 2))
              : Text(label,
                  style: const TextStyle(
                      color:      AppColors.white,
                      fontSize:   14,
                      fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
        color:        AppColors.grey,
        fontSize:     10,
        fontWeight:   FontWeight.w600,
        letterSpacing: 1.4),
  );
}
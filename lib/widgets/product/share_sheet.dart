import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_colors.dart';

Future<void> showShareSheet(
  BuildContext context, {
  required String productName,
  required double price,
  required String productId,
}) {
  final link = 'dashly.app/product/$productId';
  final shareText =
      'Check out $productName on Dashly!\n₹${price.toStringAsFixed(0)}\n$link';

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ShareSheet(text: shareText, link: link),
  );
}

class _ShareSheet extends StatelessWidget {
  final String text;
  final String link;

  const _ShareSheet({required this.text, required this.link});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Share via',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // ── App grid ─────────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _AppTile(
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  icon: Icons.chat_rounded,
                  onTap: () => _launch(
                      'https://wa.me/?text=${Uri.encodeComponent(text)}',
                      context),
                ),
                const SizedBox(width: 20),
                _AppTile(
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  icon: Icons.thumb_up_alt_rounded,
                  onTap: () => _launch(
                      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('https://$link')}&quote=${Uri.encodeComponent(text)}',
                      context),
                ),
                const SizedBox(width: 20),
                _AppTile(
                  label: 'Telegram',
                  color: const Color(0xFF2AABEE),
                  icon: Icons.send_rounded,
                  onTap: () => _launch(
                      'https://t.me/share/url?url=${Uri.encodeComponent('https://$link')}&text=${Uri.encodeComponent(text)}',
                      context),
                ),
                const SizedBox(width: 20),
                _AppTile(
                  label: 'Twitter / X',
                  color: const Color(0xFF1DA1F2),
                  icon: Icons.alternate_email_rounded,
                  onTap: () => _launch(
                      'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}',
                      context),
                ),
                const SizedBox(width: 20),
                _AppTile(
                  label: 'Email',
                  color: const Color(0xFFEA4335),
                  icon: Icons.email_rounded,
                  onTap: () => _launch(
                      'mailto:?subject=${Uri.encodeComponent('Check this out on Dashly!')}&body=${Uri.encodeComponent(text)}',
                      context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // ── Copy link row ─────────────────────────────────────────────────
          GestureDetector(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Copied to clipboard',
                        style:
                            TextStyle(color: AppColors.white, fontSize: 13)),
                    backgroundColor: Colors.green.shade900,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin:
                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.link_rounded,
                        color: AppColors.green, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Copy Link',
                            style: TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          link,
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.copy_rounded,
                      color: AppColors.greyDark, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't open this app",
                style: TextStyle(color: AppColors.white)),
            backgroundColor: AppColors.surface2,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _AppTile extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _AppTile({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.35), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: AppColors.grey, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

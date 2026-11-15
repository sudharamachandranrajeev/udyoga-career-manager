import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadBadge;

/// How each way of reaching someone looks: its name, icon and tint. Ids
/// match the conversation channels stored in the database. No brand logos
/// are drawn, only plain icons.
enum ChannelLook {
  email('email', 'Email', Icons.mail_outline, Color(0xFF2F6BFF)),
  linkedin('linkedin', 'LinkedIn', Icons.business_center_outlined, Color(0xFF0A66C2)),
  bluesky('bluesky', 'Bluesky', Icons.cloud_outlined, Color(0xFF1185FE)),
  phone('phone', 'Phone', Icons.call_outlined, Color(0xFF12B886)),
  inPerson('in_person', 'In person', Icons.handshake_outlined, Color(0xFFE8590C)),
  other('other', 'Other', Icons.chat_bubble_outline, Color(0xFF7A8499));

  const ChannelLook(this.id, this.label, this.icon, this.color);
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  /// The look for a stored channel id; anything unknown reads as Other.
  static ChannelLook of(String id) => values.firstWhere((c) => c.id == id, orElse: () => other);
}

/// A channel as a small chip: its icon and name, and the account used on it
/// when there is one ("Email · asha@example.com").
class ChannelChip extends StatelessWidget {
  const ChannelChip(this.channel, {super.key, this.account, this.onPressed});

  /// The stored channel id: email, linkedin, bluesky, phone, in_person or other.
  final String channel;
  final String? account;
  final VoidCallback? onPressed;

  /// What the chip says, also read out by screen readers.
  String get text {
    final look = ChannelLook.of(channel);
    final a = account?.trim() ?? '';
    return a.isEmpty ? look.label : '${look.label} · $a';
  }

  @override
  Widget build(BuildContext context) {
    final look = ChannelLook.of(channel);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final tint = look.color.withValues(alpha: dark ? 0.2 : 0.1);
    final fg = dark ? Color.lerp(look.color, Colors.white, 0.45)! : look.color;
    return ShadBadge(
      backgroundColor: tint,
      hoverBackgroundColor: onPressed == null ? tint : look.color.withValues(alpha: dark ? 0.28 : 0.16),
      foregroundColor: fg,
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      shape: const StadiumBorder(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(look.icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

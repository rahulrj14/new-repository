import 'package:material_ui/material_ui.dart';

import '../../catalog/nicknames.dart';
import '../../group/group_state.dart';
import '../../group/protocol.dart';
import '../theme/tokens.dart';
import '../widgets/blob_avatar.dart';

/// Friendly text for transport/permission problems.
String squadProblem(String reason) => switch (reason) {
  'bluetooth_off' => 'turn on Bluetooth to squad up 📶',
  'permission_denied' => 'Lock In needs the "Nearby devices" permission to find friends in the room. you can allow it in Settings → Apps → Lock In.',
  'location_off' => 'on this Android version, Bluetooth scanning only works with Location switched on. Lock In never reads your location.',
  'unsupported' => "this phone doesn't support Bluetooth squads 😔",
  'advertise_failed' =>
    "couldn't start the squad. try turning Bluetooth off and on.",
  'scan_failed' =>
    "couldn't scan for the squad. try turning Bluetooth off and on.",
  'not_found' =>
    "couldn't find that squad. same room? is their lobby still open?",
  'host_left' => 'the host closed the squad 👋',
  _ => 'something went wrong with Bluetooth. try again?',
};

/// Small blob + name + status for squad lists.
class MemberChip extends StatelessWidget {
  const MemberChip({
    super.key,
    required this.m,
    this.me = false,
    this.now,
    this.size = 56,
    this.onDark = false,
  });
  final GroupMember m;
  final bool me;
  final DateTime? now;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final away = now != null && isAway(m, now!);
    final cracked = m.status == MemberStatus.cracked;
    final badge = m.gone
        ? '👋'
        : away
        ? '📡'
        : switch (m.status) {
            MemberStatus.cracked => '💔',
            MemberStatus.up => '😱',
            MemberStatus.onBreak => '☕',
            MemberStatus.pass => '🆘',
            MemberStatus.locked => '🔒',
            MemberStatus.finished => '✅',
            _ => '',
          };
    final label =
        '${nicknameFor(m.nickname)}${me ? ' (you)' : ''}'
        '${m.gone
            ? ', left'
            : away
            ? ', away'
            : cracked
            ? ', cracked ${m.cracks} times'
            : ''}';
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: m.gone || away ? 0.45 : 1,
        child: SizedBox(
          width: size + 24,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  BlobAvatar(
                    avatarId: m.avatar,
                    skinId: m.skin,
                    size: size,
                    animate: false,
                    cracked: cracked,
                    mood: switch (m.status) {
                      MemberStatus.locked => BlobMood.sleepy,
                      MemberStatus.cracked ||
                      MemberStatus.up => BlobMood.shocked,
                      _ => BlobMood.idle,
                    },
                  ),
                  if (badge.isNotEmpty)
                    Positioned(
                      right: -4,
                      bottom: 0,
                      child: Text(
                        badge,
                        style: TextStyle(fontSize: size * 0.3),
                      ),
                    ),
                ],
              ),
              Text(
                me ? 'you' : nicknameFor(m.nickname).split(' ').last,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kFont,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: onDark ? Colors.white : LockColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

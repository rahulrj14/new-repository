import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../catalog/avatars.dart';
import '../../catalog/nicknames.dart';
import '../../catalog/skins.dart';
import '../../platform/device_bridge.dart';
import '../../storage/db.dart';
import '../../storage/profile_store.dart';
import '../theme/tokens.dart';
import '../widgets/blob_avatar.dart';
import '../widgets/common.dart';

class MeTab extends ConsumerStatefulWidget {
  const MeTab({super.key});

  @override
  ConsumerState<MeTab> createState() => _MeTabState();
}

class _MeTabState extends ConsumerState<MeTab> {
  /// Captured when the tab opens, so "new" badges show once, then clear.
  Set<int> _newOnOpen = {};

  @override
  void initState() {
    super.initState();
    _newOnOpen = {...ref.read(progressValueProvider).unseenSkins};
    if (_newOnOpen.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(progressProvider.notifier).markSkinsSeen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    if (profile == null) return const SizedBox.shrink();
    final p = ref.watch(progressValueProvider);
    final settings = ref.watch(settingsProvider);
    final text = Theme.of(context).textTheme;
    final level = p.level;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        BlueHeader(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                BlobAvatar(avatarId: profile.avatarId, skinId: profile.skinId, size: 140, mood: BlobMood.happy),
                Text(nicknameFor(profile.nicknameId), style: text.headlineMedium?.copyWith(color: Colors.white)),
                Text('LV ${level.number} · ${level.name}',
                    style: text.titleMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  StatTile(value: '${p.auraTotal}', label: 'aura', color: LockColors.blue),
                  const SizedBox(width: 10),
                  StatTile(value: '${p.sessions}', label: 'sessions'),
                  const SizedBox(width: 10),
                  StatTile(value: '${p.streak.longest}', label: 'best streak'),
                ],
              ),
              const SizedBox(height: 22),
              Text('skins', style: text.titleLarge),
              Text('earned by keeping your phone down. tap to wear.', style: text.bodyMedium),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.78,
                children: [
                  for (final s in skins)
                    _SkinTile(
                      skin: s,
                      avatarId: profile.avatarId,
                      unlocked: p.unlockedSkins.contains(s.id) || isUnlocked(s, p.unlockStats),
                      equipped: profile.skinId == s.id,
                      isNew: _newOnOpen.contains(s.id),
                      onTap: (unlocked) {
                        if (unlocked) {
                          HapticFeedback.selectionClick();
                          ref.read(profileProvider.notifier).setSkin(s.id);
                        } else {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(content: Text('🔒 ${s.name}: ${s.requirement}')));
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Text('your blob', style: text.titleLarge),
              const SizedBox(height: 10),
              SizedBox(
                height: 84,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final a in avatars)
                      Semantics(
                        button: true,
                        selected: profile.avatarId == a.id,
                        label: a.name,
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => ref.read(profileProvider.notifier).setAvatar(a.id),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: profile.avatarId == a.id ? LockColors.blue : LockColors.line, width: 2),
                            ),
                            child: BlobAvatar(avatarId: a.id, size: 70, animate: false),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text('history', style: text.titleLarge),
              const SizedBox(height: 10),
              if (p.recent.isEmpty)
                LockCard(child: Text('no sessions yet. your first one goes here ✨', style: text.bodyLarge))
              else
                LockCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (final r in p.recent.take(10)) _HistoryRow(r: r),
                    ],
                  ),
                ),
              const SizedBox(height: 22),
              Text('settings', style: text.titleLarge),
              const SizedBox(height: 10),
              LockCard(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text('haptics', style: text.titleMedium),
                      value: settings.haptics,
                      onChanged: ref.read(settingsProvider.notifier).setHaptics,
                    ),
                    SwitchListTile(
                      title: Text('reduce motion', style: text.titleMedium),
                      value: settings.reduceMotion,
                      onChanged: ref.read(settingsProvider.notifier).setReduceMotion,
                    ),
                    ListTile(
                      title: Text('keep sessions alive', style: text.titleMedium),
                      subtitle: Text('battery saver → no restrictions (Xiaomi, Samsung, OnePlus)',
                          style: text.bodyMedium),
                      trailing: const Icon(Icons.chevron_right_rounded, color: LockColors.muted),
                      onTap: () => ref.read(deviceBridgeProvider).openAppSettings(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LockCard(
                color: LockColors.blueSoft,
                child: Text(
                  '🔒 no account. no tracking. no ads. Lock In has no internet access at all — '
                  'your aura, streaks and blob never leave this phone.',
                  style: text.bodyLarge?.copyWith(color: LockColors.blueDeep),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkinTile extends StatelessWidget {
  const _SkinTile({
    required this.skin,
    required this.avatarId,
    required this.unlocked,
    required this.equipped,
    required this.isNew,
    required this.onTap,
  });
  final Skin skin;
  final int avatarId;
  final bool unlocked;
  final bool equipped;
  final bool isNew;
  final ValueChanged<bool> onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: equipped,
      label: '${skin.name}. ${unlocked ? (equipped ? 'Wearing' : 'Unlocked') : 'Locked: ${skin.requirement}'}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => onTap(unlocked),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: equipped ? LockColors.blue : LockColors.line, width: equipped ? 3 : 2),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: unlocked ? 1 : 0.35,
                      child: BlobAvatar(avatarId: avatarId, skinId: skin.id, size: 72, animate: false),
                    ),
                    Text(skin.name, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      unlocked ? (equipped ? 'wearing' : 'tap to wear') : '🔒 ${skin.requirement}',
                      style: text.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: equipped ? LockColors.blue : LockColors.muted,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isNew)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: LockColors.coral, borderRadius: BorderRadius.circular(LockRadius.pill)),
                    child: const Text('new',
                        style: TextStyle(fontFamily: kFont, color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.r});
  final SessionRow r;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final d = r.startedAt;
    final when = '${d.day} ${months[d.month - 1]} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final mins = r.lockedSeconds ~/ 60;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: r.cracks == 0 ? LockColors.blueSoft : LockColors.coral.withValues(alpha: 0.12),
        child: Text(r.cracks == 0 ? '🔒' : '💔'),
      ),
      title: Text('$mins min locked${r.cracks > 0 ? ' · ${r.cracks} crack${r.cracks == 1 ? '' : 's'}' : ''}',
          style: text.titleMedium),
      subtitle: Text(when, style: text.bodyMedium),
      trailing: Text('+${r.aura} ✦', style: text.titleMedium?.copyWith(color: LockColors.blue)),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../catalog/avatars.dart';
import '../../platform/device_bridge.dart';
import '../../storage/profile_store.dart';
import '../theme/tokens.dart';
import '../widgets/blob_avatar.dart';

void showSettingsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final profile = ref.watch(profileProvider);
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('settings', style: text.headlineMedium),
            const SizedBox(height: 16),
            Text('your blob', style: text.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 76,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final a in avatars)
                    Semantics(
                      button: true,
                      selected: profile?.avatarId == a.id,
                      label: a.name,
                      child: GestureDetector(
                        onTap: () => ref.read(profileProvider.notifier).setAvatar(a.id),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: profile?.avatarId == a.id ? a.color : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: BlobAvatar(avatarId: a.id, size: 68, animate: false),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('haptics', style: text.titleMedium),
              value: s.haptics,
              onChanged: ref.read(settingsProvider.notifier).setHaptics,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('reduce motion', style: text.titleMedium),
              value: s.reduceMotion,
              onChanged: ref.read(settingsProvider.notifier).setReduceMotion,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('keep sessions alive', style: text.titleMedium),
              subtitle: Text('battery saver → no restrictions. needed on Xiaomi, Samsung, OnePlus.',
                  style: text.bodyMedium),
              trailing: const Icon(Icons.open_in_new_rounded, color: LockColors.muted),
              onTap: () => ref.read(deviceBridgeProvider).openAppSettings(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: LockColors.surfaceHi, borderRadius: BorderRadius.circular(20)),
              child: Text(
                '🔒 no account. no tracking. no ads. this app has no internet access at all — '
                'your aura, streaks and blob never leave this phone.',
                style: text.bodyMedium?.copyWith(color: LockColors.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

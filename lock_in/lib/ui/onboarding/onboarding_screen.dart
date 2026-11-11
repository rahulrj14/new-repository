import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../catalog/avatars.dart';
import '../../catalog/nicknames.dart';
import '../../storage/profile_store.dart';
import '../theme/tokens.dart';
import '../widgets/blob_avatar.dart';
import '../widgets/common.dart';

/// Two taps to get going: pick a blob, accept (or reroll) a nickname.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int? _avatar;
  int _nickname = randomNicknameId();
  bool _naming = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _naming ? _nameStep(text) : _pickStep(text),
          ),
        ),
      ),
    );
  }

  Widget _pickStep(TextTheme text) {
    return Column(
      key: const ValueKey('pick'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('pick your\nblob 👀', style: text.headlineLarge),
        const SizedBox(height: 8),
        Text('it cracks when you touch your phone.', style: text.bodyMedium),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (final a in avatars)
                Semantics(
                  button: true,
                  selected: _avatar == a.id,
                  label: a.name,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _avatar = a.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: LockColors.surface,
                        borderRadius: BorderRadius.circular(LockRadius.card),
                        border: Border.all(
                          color: _avatar == a.id ? a.color : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BlobAvatar(
                            avatarId: a.id,
                            size: 96,
                            mood: _avatar == a.id ? BlobMood.happy : BlobMood.idle,
                            animate: _avatar == a.id,
                          ),
                          Text(a.name, style: text.titleMedium),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _avatar == null ? null : () => setState(() => _naming = true),
          child: const Text('next'),
        ),
      ],
    );
  }

  Widget _nameStep(TextTheme text) {
    final avatar = avatarById(_avatar ?? 0);
    return Column(
      key: const ValueKey('name'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _naming = false),
            child: const Text('← back'),
          ),
        ),
        const Spacer(),
        Center(
          child: Glow(
            color: avatar.color,
            child: BlobAvatar(avatarId: avatar.id, size: 180, mood: BlobMood.happy),
          ),
        ),
        const SizedBox(height: 16),
        Text("you're", textAlign: TextAlign.center, style: text.bodyLarge?.copyWith(color: LockColors.muted)),
        Semantics(
          liveRegion: true,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Text(
              nicknameFor(_nickname),
              key: ValueKey(_nickname),
              textAlign: TextAlign.center,
              style: text.headlineLarge?.copyWith(color: avatar.color),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(160, 52)),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _nickname = randomNicknameId());
            },
            icon: const Text('🎲', style: TextStyle(fontSize: 20)),
            label: const Text('reroll'),
          ),
        ),
        const Spacer(),
        Text(
          'no account. no tracking. no internet.\neverything stays on this phone.',
          textAlign: TextAlign.center,
          style: text.bodyMedium,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () async {
            await ref.read(profileProvider.notifier).create(avatarId: avatar.id, nicknameId: _nickname);
            if (mounted) context.go('/');
          },
          child: const Text("let's go"),
        ),
      ],
    );
  }
}

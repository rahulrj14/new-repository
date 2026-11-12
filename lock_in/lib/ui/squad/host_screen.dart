import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../catalog/nicknames.dart';
import '../../catalog/vibes.dart';
import '../../config.dart';
import '../../group/group_controller.dart';
import '../../group/stakes.dart';
import '../../session/session_controller.dart';
import '../theme/tokens.dart';
import '../widgets/blob_avatar.dart';
import '../widgets/common.dart';
import 'squad_widgets.dart';

class HostScreen extends ConsumerStatefulWidget {
  const HostScreen({super.key});

  @override
  ConsumerState<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends ConsumerState<HostScreen> {
  String? _error;
  bool _starting = true;
  bool _showGetApp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    setState(() {
      _error = null;
      _starting = true;
    });
    final err = await ref.read(groupProvider.notifier).host();
    if (mounted) {
      setState(() {
        _error = err;
        _starting = false;
      });
    }
  }

  Future<void> _close() async {
    await ref.read(groupProvider.notifier).leave();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionProvider, (prev, next) {
      if (prev == null && next != null) context.go('/session');
    });
    final v = ref.watch(groupProvider);
    final text = Theme.of(context).textTheme;

    if (_error != null) {
      return SquadProblemScreen(
        message: squadProblem(_error!),
        onRetry: _open,
        onClose: _close,
      );
    }
    if (_starting || v == null || !v.isHost) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final c = v.config;
    final friends = v.members.length - 1;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            BlueHeader(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Close squad',
                          onPressed: _close,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'your squad',
                          style: text.headlineMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _QrToggle(
                      getApp: _showGetApp,
                      onChanged: (v) => setState(() => _showGetApp = v),
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      label: _showGetApp
                          ? 'Play Store code. Friends without Lock In scan this with their camera.'
                          : 'Join code. Friends scan this with Lock In.',
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(LockRadius.card),
                        ),
                        child: QrImageView(
                          // The join code never goes into the store link:
                          // opening a URL would hand the session key to others.
                          data: _showGetApp ? kPlayUrl : v.code.encode(),
                          size: 210,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.circle,
                            color: _showGetApp
                                ? LockColors.blue
                                : LockColors.ink,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.circle,
                            color: _showGetApp
                                ? LockColors.blue
                                : LockColors.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _showGetApp
                          ? 'no Lock In yet? scan with the camera → Play Store'
                          : 'friends: Lock In → with friends → join',
                      textAlign: TextAlign.center,
                      style: text.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (v.bleProblem != null) ...[
                    LockCard(
                      color: const Color(0xFFFFF4D6),
                      child: Text(
                        '📶 ${squadProblem(v.bleProblem!)}${kDebugTools ? '\n🧪 fake friends still work.' : ''}',
                        style: text.bodyLarge,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  for (final p in v.pending) ...[
                    _RequestCard(
                      avatar: p.request.avatar,
                      skin: p.request.skin,
                      nickname: p.request.nickname,
                      onApprove: () =>
                          ref.read(groupProvider.notifier).approve(p.peer),
                      onDeny: () =>
                          ref.read(groupProvider.notifier).deny(p.peer),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    'in the squad (${v.members.length})',
                    style: text.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  LockCard(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 8,
                      children: [
                        for (final m in v.sorted)
                          MemberChip(m: m, me: m.index == v.myIndex),
                      ],
                    ),
                  ),
                  if (kDebugTools) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          ref.read(groupProvider.notifier).addSimFriend(),
                      child: const Text('🧪 add a fake friend'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text('settings', style: text.titleLarge),
                  const SizedBox(height: 10),
                  _Chips<int>(
                    values: const [25, 50, 90, 0],
                    selected: c.lengthMin,
                    label: (m) => m == 0 ? '∞' : '${m}m',
                    onTap: (m) => ref
                        .read(groupProvider.notifier)
                        .setOptions(lengthMin: m),
                  ),
                  const SizedBox(height: 10),
                  _Chips<Vibe>(
                    values: Vibe.values,
                    selected:
                        Vibe.values[c.vibe.clamp(0, Vibe.values.length - 1)],
                    label: (v) => '${v.emoji} ${v.label}',
                    onTap: (vb) =>
                        ref.read(groupProvider.notifier).setOptions(vibe: vb),
                  ),
                  const SizedBox(height: 10),
                  LockCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text(
                            'last one standing 👑',
                            style: text.titleMedium,
                          ),
                          subtitle: Text(
                            'ends when only one person has zero cracks',
                            style: text.bodyMedium,
                          ),
                          value: c.lastStanding,
                          onChanged: (b) => ref
                              .read(groupProvider.notifier)
                              .setOptions(lastStanding: b),
                        ),
                        if (c.lengthMin == 0 || c.lengthMin > 25)
                          SwitchListTile(
                            title: Text('breaks ☕', style: text.titleMedium),
                            subtitle: Text(
                              '25 on, 5 off — for everyone',
                              style: text.bodyMedium,
                            ),
                            value: c.breaks,
                            onChanged: (b) => ref
                                .read(groupProvider.notifier)
                                .setOptions(breaks: b),
                          ),
                        ListTile(
                          title: Text('stakes', style: text.titleMedium),
                          subtitle: Text(
                            stakeText(c.stake),
                            style: text.bodyMedium,
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _pickStake(context, c.stake),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: friends == 0
                        ? null
                        : () => ref.read(groupProvider.notifier).start(),
                    child: Text(
                      friends == 0
                          ? 'waiting for friends…'
                          : 'start with $friends ${friends == 1 ? 'friend' : 'friends'} 🔒',
                    ),
                  ),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickStake(BuildContext context, int current) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (var i = 0; i < stakes.length; i++)
              ListTile(
                title: Text(
                  stakes[i],
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: i == current
                    ? const Icon(Icons.check_rounded, color: LockColors.blue)
                    : null,
                onTap: () {
                  ref.read(groupProvider.notifier).setOptions(stake: i);
                  Navigator.pop(sheet);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _QrToggle extends StatelessWidget {
  const _QrToggle({required this.getApp, required this.onChanged});
  final bool getApp;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool value) {
      final on = getApp == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(LockRadius.pill),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: kFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: on ? LockColors.blue : Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 280,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(LockRadius.pill),
      ),
      child: Row(children: [seg('join code', false), seg('get the app', true)]),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.avatar,
    required this.skin,
    required this.nickname,
    required this.onApprove,
    required this.onDeny,
  });
  final int avatar;
  final int skin;
  final int nickname;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final name = nicknameFor(nickname);
    return LockCard(
      color: LockColors.blueSoft,
      child: Row(
        children: [
          BlobAvatar(
            avatarId: avatar,
            skinId: skin,
            size: 56,
            animate: false,
            mood: BlobMood.happy,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: text.titleLarge),
                Text('wants to join', style: text.bodyMedium),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Say no to $name',
            iconSize: 28,
            onPressed: onDeny,
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: 6),
          IconButton.filled(
            tooltip: 'Let $name in',
            iconSize: 28,
            onPressed: onApprove,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
    );
  }
}

class _Chips<T> extends StatelessWidget {
  const _Chips({
    required this.values,
    required this.selected,
    required this.label,
    required this.onTap,
  });
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          ChoiceChip(
            label: Text(label(v)),
            selected: v == selected,
            onSelected: (_) => onTap(v),
            labelStyle: TextStyle(
              fontFamily: kFont,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: v == selected ? LockColors.blue : LockColors.ink,
            ),
            selectedColor: LockColors.blueSoft,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: v == selected ? LockColors.blue : LockColors.line,
              width: 2,
            ),
            shape: const StadiumBorder(),
            showCheckmark: false,
          ),
      ],
    );
  }
}

/// Friendly full-screen problem with retry.
class SquadProblemScreen extends StatelessWidget {
  const SquadProblemScreen({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onClose,
  });
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Center(
                child: BlobAvatar(
                  avatarId: 2,
                  size: 140,
                  mood: BlobMood.shocked,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: text.titleLarge,
              ),
              const Spacer(),
              FilledButton(onPressed: onRetry, child: const Text('try again')),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: onClose, child: const Text('back')),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../catalog/nicknames.dart';
import '../../catalog/vibes.dart';
import '../../group/group_controller.dart';
import '../../group/group_state.dart';
import '../../group/protocol.dart';
import '../../group/stakes.dart';
import '../../group/transport.dart';
import '../../session/session_controller.dart';
import '../widgets/blob_avatar.dart';
import '../widgets/common.dart';
import 'host_screen.dart';
import 'squad_widgets.dart';

class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  String? _error;
  JoinCode? _code;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  Future<void> _scan() async {
    setState(() => _error = null);
    final raw = await NativeBleTransport.scanQr();
    if (!mounted) return;
    if (raw == null) {
      context.pop();
      return;
    }
    final code = JoinCode.tryParse(raw);
    if (code == null) {
      setState(() => _error = "that's not a Lock In code 🤔");
      return;
    }
    _code = code;
    final err = await ref.read(groupProvider.notifier).join(code);
    if (mounted && err != null) setState(() => _error = squadProblem(err));
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

    final err =
        _error ??
        switch (v?.stage) {
          JoinStage.failed => squadProblem(v?.failure ?? ''),
          JoinStage.denied => 'the host said not this time. no worries ✌️',
          _ => null,
        };
    if (err != null) {
      return SquadProblemScreen(message: err, onRetry: _scan, onClose: _close);
    }

    final code = _code ?? v?.code;
    if (v == null || code == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final host = nicknameFor(code.hostNickname);

    if (v.stage != JoinStage.inGroup) {
      final connecting = v.stage == JoinStage.connecting;
      return Scaffold(
        body: BlueHeader(
          child: SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Cancel',
                      onPressed: _close,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Semantics(
                    liveRegion: true,
                    child: ChatBubble(
                      text: connecting
                          ? "looking for $host's squad 📡"
                          : 'asked $host to let you in ⏳',
                    ),
                  ),
                  BlobAvatar(
                    avatarId: code.hostAvatar,
                    size: 170,
                    mood: connecting ? BlobMood.idle : BlobMood.happy,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    host,
                    style: text.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    connecting
                        ? 'stay close to their phone'
                        : "they'll tap ✓ on their screen",
                    style: text.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final c = v.config;
    final vibe = Vibe.values[c.vibe.clamp(0, Vibe.values.length - 1)];
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
                          tooltip: 'Leave squad',
                          onPressed: _close,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "$host's squad",
                            style: text.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const ChatBubble(
                      text: "you're in! 🎉 waiting for the host to start",
                    ),
                    if (v.hostGone)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '📡 lost the host for a sec… reconnecting',
                          style: text.bodyLarge?.copyWith(color: Colors.white),
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
                  const SizedBox(height: 16),
                  LockCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Line(
                          '⏱️',
                          c.lengthMin == 0
                              ? 'open-ended'
                              : '${c.lengthMin} minutes',
                        ),
                        _Line(vibe.emoji, '${vibe.label} vibe'),
                        if (c.lastStanding)
                          const _Line('👑', 'last one standing'),
                        if (c.breaks) const _Line('☕', 'breaks: 25 on, 5 off'),
                        _Line('🎲', stakeText(c.stake)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.emoji, this.text);
  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    ),
  );
}

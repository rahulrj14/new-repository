import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../platform/device_bridge.dart';
import '../../storage/profile_store.dart';
import '../theme/tokens.dart';
import '../widgets/blob_avatar.dart';
import '../widgets/common.dart';

/// Brands known to kill background apps unless the user allows them.
enum PhoneMaker { xiaomi, samsung, oppo, vivo, huawei, other }

PhoneMaker phoneMaker(String? manufacturer) {
  final m = (manufacturer ?? '').toLowerCase();
  if (m.contains('xiaomi') || m.contains('redmi') || m.contains('poco')) {
    return PhoneMaker.xiaomi;
  }
  if (m.contains('samsung')) return PhoneMaker.samsung;
  if (m.contains('oppo') || m.contains('oneplus') || m.contains('realme')) {
    return PhoneMaker.oppo;
  }
  if (m.contains('vivo') || m.contains('iqoo')) return PhoneMaker.vivo;
  if (m.contains('huawei') || m.contains('honor')) return PhoneMaker.huawei;
  return PhoneMaker.other;
}

/// True for phones that need the walkthrough before a first long session.
bool needsKeepAlive(Map<String, Object?> info) =>
    phoneMaker(info['manufacturer'] as String?) != PhoneMaker.other ||
    info['batteryOptimized'] == true;

const keepAliveDoneKey = 'keepAliveDone';

class _Step {
  const _Step(this.title, this.how, this.action, this.button);
  final String title;
  final String how;

  /// autostart | app | battery | none
  final String action;
  final String button;
}

List<_Step> _steps(PhoneMaker m) => switch (m) {
  PhoneMaker.xiaomi => const [
    _Step(
      'turn on Autostart',
      'find Lock In in the list and switch it on',
      'autostart',
      'open Autostart',
    ),
    _Step(
      'battery saver: no restrictions',
      'App info → Battery saver → No restrictions',
      'app',
      'open app info',
    ),
    _Step(
      'lock it in recents',
      'open Recents, press and hold Lock In (or swipe it down) → tap the 🔒',
      'none',
      '',
    ),
  ],
  PhoneMaker.samsung => const [
    _Step(
      'battery: unrestricted',
      'App info → Battery → Unrestricted',
      'app',
      'open app info',
    ),
    _Step(
      'not a sleeping app',
      'Settings → Battery → Background usage limits → make sure Lock In isn\'t in "Sleeping" or "Deep sleeping" apps',
      'autostart',
      'open battery settings',
    ),
  ],
  PhoneMaker.oppo => const [
    _Step(
      'allow auto launch',
      'find Lock In and switch it on',
      'autostart',
      'open auto launch',
    ),
    _Step(
      'allow background activity',
      'App info → Battery usage → Allow background activity',
      'app',
      'open app info',
    ),
  ],
  PhoneMaker.vivo => const [
    _Step(
      'allow background running',
      'find Lock In and allow it',
      'autostart',
      'open background settings',
    ),
    _Step(
      'high background power use',
      'App info → Battery → Allow high background power consumption',
      'app',
      'open app info',
    ),
  ],
  PhoneMaker.huawei => const [
    _Step(
      'manage launch manually',
      'App launch → Lock In → manage manually → allow all three',
      'autostart',
      'open app launch',
    ),
    _Step(
      'battery',
      'App info → Battery → allow background activity',
      'app',
      'open app info',
    ),
  ],
  PhoneMaker.other => const [
    _Step(
      'battery optimisation: off',
      'All apps → Lock In → Don\'t optimise',
      'battery',
      'open battery list',
    ),
  ],
};

String _brand(PhoneMaker m) => switch (m) {
  PhoneMaker.xiaomi => 'Xiaomi / Redmi / POCO',
  PhoneMaker.samsung => 'Samsung',
  PhoneMaker.oppo => 'OnePlus / Oppo / Realme',
  PhoneMaker.vivo => 'Vivo / iQOO',
  PhoneMaker.huawei => 'Huawei / Honor',
  PhoneMaker.other => 'your phone',
};

/// "Keep sessions alive": phone-maker specific steps so the system doesn't
/// kill a session while the phone is locked. Shown once before the first
/// session on risky phones, and any time from Me → settings.
class KeepAliveScreen extends ConsumerStatefulWidget {
  const KeepAliveScreen({super.key});

  @override
  ConsumerState<KeepAliveScreen> createState() => _KeepAliveScreenState();
}

class _KeepAliveScreenState extends ConsumerState<KeepAliveScreen>
    with WidgetsBindingObserver {
  final _done = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from Settings: re-check what Android reports.
    if (state == AppLifecycleState.resumed) ref.invalidate(deviceInfoProvider);
  }

  Future<void> _run(_Step s) async {
    final b = ref.read(deviceBridgeProvider);
    switch (s.action) {
      case 'autostart':
        await b.openAutostart();
      case 'app':
        await b.openAppSettings();
      case 'battery':
        await b.openBatteryList();
    }
  }

  Future<void> _finish() async {
    await ref.read(prefsProvider).setBool(keepAliveDoneKey, true);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(deviceInfoProvider).value ?? const {};
    final maker = phoneMaker(info['manufacturer'] as String?);
    final steps = _steps(maker);
    final optimized = info['batteryOptimized'] == true;
    final text = Theme.of(context).textTheme;

    return Scaffold(
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
                        tooltip: 'Back',
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'keep sessions alive',
                          style: text.headlineMedium?.copyWith(
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ChatBubble(
                    text: '${_brand(maker)} phones nap apps to save battery 😴',
                  ),
                  const BlobAvatar(
                    avatarId: 6,
                    size: 120,
                    mood: BlobMood.sleepy,
                  ),
                  Text(
                    "a quick fix so your session doesn't get cut off while your phone's locked",
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
                Semantics(
                  liveRegion: true,
                  child: LockCard(
                    color: optimized
                        ? const Color(0xFFFFF4D6)
                        : const Color(0xFFE9FBF3),
                    child: Row(
                      children: [
                        Text(
                          optimized ? '⚠️' : '✅',
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            optimized
                                ? 'Android says battery optimisation is still on for Lock In'
                                : 'Android says Lock In is allowed to run in the background',
                            style: text.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < steps.length; i++) ...[
                  LockCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _done.contains(i)
                                ? LockColors.mint
                                : LockColors.blueSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _done.contains(i) ? '✓' : '${i + 1}',
                            style: text.titleMedium?.copyWith(
                              color: _done.contains(i)
                                  ? Colors.white
                                  : LockColors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(steps[i].title, style: text.titleLarge),
                              Text(steps[i].how, style: text.bodyMedium),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (steps[i].action != 'none')
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        minimumSize: const Size(0, 44),
                                      ),
                                      onPressed: () async {
                                        await _run(steps[i]);
                                        setState(() => _done.add(i));
                                      },
                                      child: Text(steps[i].button),
                                    ),
                                  TextButton(
                                    onPressed: () => setState(
                                      () => _done.contains(i)
                                          ? _done.remove(i)
                                          : _done.add(i),
                                    ),
                                    child: Text(
                                      _done.contains(i) ? 'undo' : 'done ✓',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
                Text(
                  "names differ a little between versions. if a button opens the wrong page, use the step's directions in Settings.",
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _finish,
                  child: const Text("all set 💪"),
                ),
                SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

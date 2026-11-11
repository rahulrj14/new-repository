import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'detection/device_signals.dart';
import 'detection/grace_tracker.dart';

/// Lock In spike, part 1: detection lab.
///
/// Runs on a single phone. Tests whether "face-down" and "lock" modes can
/// detect phone use reliably. No Bluetooth yet, no storage, no network.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LabApp());
}

class LabApp extends StatelessWidget {
  const LabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lock In Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFFB6FF3B),
        useMaterial3: true,
      ),
      home: const LabScreen(),
    );
  }
}

enum LabMode { faceDown, lock }

class LogLine {
  LogLine(this.at, this.text, {this.important = false});
  final DateTime at;
  final String text;
  final bool important;
}

class LabScreen extends StatefulWidget {
  const LabScreen({super.key});

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  static const setupPeriod = Duration(seconds: 15);
  static const heartbeatEvery = Duration(seconds: 5);

  final _signals = DeviceSignals();
  final _log = <LogLine>[];
  StreamSubscription<RawDeviceEvent>? _sub;
  Timer? _heartbeat;
  Timer? _ui;

  Map<String, Object?> _info = {};
  LabMode _mode = LabMode.faceDown;
  GraceTracker? _tracker;
  DateTime? _startedAt;
  DateTime? _lastBeat;
  Duration _longestGap = Duration.zero;
  int _gaps = 0;
  int _graceCancels = 0;
  double? _batteryStart;
  double? _batteryNow;

  bool get _running => _tracker != null;
  bool get _isAndroid => _info['platform'] == 'android';

  @override
  void initState() {
    super.initState();
    _mode = defaultTargetPlatform == TargetPlatform.android ? LabMode.lock : LabMode.faceDown;
    _sub = _signals.events.listen(_onRaw, onError: (Object e) => _add('channel error: $e'));
    _refreshInfo();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _heartbeat?.cancel();
    _ui?.cancel();
    super.dispose();
  }

  Future<void> _refreshInfo() async {
    try {
      final info = await _signals.snapshot();
      setState(() => _info = info);
    } on MissingPluginException {
      setState(() => _info = {'platform': 'unsupported (no native layer)'});
    }
  }

  void _add(String text, {DateTime? at, bool important = false}) {
    setState(() => _log.add(LogLine(at ?? DateTime.now(), text, important: important)));
  }

  void _onRaw(RawDeviceEvent e) {
    if (e.battery >= 0) _batteryNow = e.battery;
    final tracker = _tracker;
    final delay = DateTime.now().difference(e.at);
    final lateNote = delay > const Duration(seconds: 2) ? ' (delivered ${delay.inSeconds}s late)' : '';
    _add('${e.name}$lateNote', at: e.at);
    final s = e.signal;
    if (tracker == null || s == null) return;
    _report(tracker.onSignal(s, e.at));
  }

  void _report(List<TrackerEvent> events) {
    for (final ev in events) {
      switch (ev) {
        case GraceStarted():
          _add('⏳ grace started (10s to put it back down)', at: ev.at, important: true);
          HapticFeedback.lightImpact();
        case GraceCancelled(:final after):
          _graceCancels++;
          _add('✅ back down after ${after.inSeconds}s — no crack', at: ev.at, important: true);
        case Cracked(:final noticedLate):
          _add('💥 CRACK${noticedLate ? ' (noticed late: app was asleep)' : ''}',
              at: ev.at, important: true);
          HapticFeedback.heavyImpact();
        case Rearmed():
          _add('🔒 down again — re-armed', at: ev.at, important: true);
      }
    }
  }

  Future<void> _start() async {
    final now = DateTime.now();
    await _refreshInfo();
    final faceDown = _mode == LabMode.faceDown;
    final ok = await _signals.setFaceDownMode(faceDown);
    await _signals.startSession();
    if (faceDown && !ok) {
      _add('⚠️ This device has no proximity sensor; face-down mode cannot work here.',
          important: true);
    }
    final armAt = now.add(setupPeriod);
    setState(() {
      _log.clear();
      _startedAt = now;
      _lastBeat = now;
      _longestGap = Duration.zero;
      _gaps = 0;
      _graceCancels = 0;
      _batteryStart = (_info['battery'] as num?)?.toDouble();
      _batteryNow = _batteryStart;
      _tracker = GraceTracker(
        armedAt: armAt,
        initiallyActive: true,
        initiallyCovered: (_info['proximityCovered'] as bool?) ?? false,
      );
    });
    _add('▶︎ started in ${faceDown ? 'FACE-DOWN' : 'LOCK'} mode. '
        '${faceDown ? 'Put the phone face down' : 'Press the side button to lock'} '
        'within ${setupPeriod.inSeconds}s.', important: true);
    Timer(setupPeriod, () {
      final t = _tracker;
      if (t == null) return;
      _add('armed — detection is live', important: true);
      _report(t.arm());
    });
    _heartbeat = Timer.periodic(heartbeatEvery, (_) => _beat());
    _ui = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  void _beat() {
    final now = DateTime.now();
    final last = _lastBeat;
    if (last != null) {
      final gap = now.difference(last);
      if (gap > heartbeatEvery * 1.6) {
        _gaps++;
        if (gap > _longestGap) _longestGap = gap;
        _add(
            _isAndroid
                ? '😴 CPU slept ${gap.inSeconds}s (normal when locked; unlocks still wake it)'
                : '😴 app was asleep for ${gap.inSeconds}s',
            at: last);
      }
    }
    _lastBeat = now;
    final t = _tracker;
    if (t != null) _report(t.tick(now));
  }

  Future<void> _stop() async {
    _heartbeat?.cancel();
    _ui?.cancel();
    await _signals.setFaceDownMode(false);
    await _signals.stopSession();
    await _refreshInfo();
    _add('■ stopped', important: true);
    setState(() => _tracker = null);
  }

  String _summary() {
    final t = _tracker;
    final start = _startedAt;
    final b0 = _batteryStart, b1 = _batteryNow;
    final drain = (b0 != null && b1 != null && b0 >= 0 && b1 >= 0)
        ? '${((b0 - b1) * 100).toStringAsFixed(0)}%'
        : 'unknown';
    return [
      'Lock In Lab — ${_mode == LabMode.faceDown ? 'face-down' : 'lock'} mode',
      'device: ${_info['model'] ?? '?'} ${_info['system'] ?? ''}',
      if (_isAndroid) 'battery optimisation on: ${_info['batteryOptimized'] ?? '?'}',
      'passcode set: ${_info['passcodeSet'] ?? '?'}  proximity sensor: ${_info['proximitySupported'] ?? '?'}',
      if (start != null) 'duration: ${_fmt(DateTime.now().difference(start))}',
      'cracks: ${t?.crackCount ?? '-'}  grace saves: $_graceCancels',
      'sleep gaps: $_gaps  longest: ${_longestGap.inSeconds}s',
      'battery drain: $drain',
    ].join('\n');
  }

  String _exportText() {
    final b = StringBuffer(_summary())..writeln()..writeln();
    for (final l in _log) {
      b.writeln('${l.at.toIso8601String()}  ${l.text}');
    }
    return b.toString();
  }

  static String _fmt(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = _tracker;
    final status = t == null
        ? 'Not running'
        : t.isCracked
            ? '💥 Cracked'
            : t.inGrace
                ? '⏳ Grace…'
                : t.isDown
                    ? '🔒 Down'
                    : 'Phone is up';
    return Scaffold(
      appBar: AppBar(title: const Text('Lock In Lab')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_running) ...[
                SegmentedButton<LabMode>(
                  segments: const [
                    ButtonSegment(value: LabMode.faceDown, label: Text('Face-down')),
                    ButtonSegment(value: LabMode.lock, label: Text('Lock')),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
                const SizedBox(height: 8),
                Text(
                  _mode == LabMode.faceDown
                      ? 'Keep Lock In open and put the phone face down. The screen goes dark. '
                          'Picking it up for more than 10 s is a crack.'
                      : _isAndroid
                          ? 'Lock the phone with the power button. Unlocking it for more than '
                              '10 s is a crack, even if you open a different app.'
                          : 'Lock the phone with the side button. Unlocking counts as a crack. '
                              'On iPhone this is only noticed when you come back to the app.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                if (_info['passcodeSet'] == false)
                  Text(
                      _isAndroid
                          ? '⚠️ No screen lock set: turning the screen on will count as unlocking.'
                          : '⚠️ No passcode set: lock detection will not work.',
                      style: const TextStyle(color: Colors.orangeAccent)),
                if (_info['batteryOptimized'] == true)
                  TextButton(
                    onPressed: _signals.openBatterySettings,
                    child: const Text(
                        '⚠️ Battery optimisation is on for this app. Some phones kill '
                        'background apps. Tap to open settings, find "Lock In Lab", choose "Don\'t optimise".'),
                  ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Text(status,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
              ),
              Text(_summary(), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                      onPressed: _running ? _stop : _start,
                      child: Text(_running ? 'Stop' : 'Start'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(56, 56)),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _exportText()));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Log copied. Paste it to Claude.')));
                      }
                    },
                    child: const Text('Copy log'),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: _log.length,
                  itemBuilder: (_, i) {
                    final l = _log[_log.length - 1 - i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${_time(l.at)}  ${l.text}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: l.important ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

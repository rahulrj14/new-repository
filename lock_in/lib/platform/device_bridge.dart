import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../detection/grace_tracker.dart';

/// One raw event from the native layer, with the native timestamp.
class DeviceEvent {
  DeviceEvent(this.name, this.at);
  final String name;
  final DateTime at;

  DeviceSignal? get signal => switch (name) {
    'appActive' => DeviceSignal.appActive,
    'appInactive' => DeviceSignal.appInactive,
    'deviceLocked' => DeviceSignal.deviceLocked,
    'deviceUnlocked' => DeviceSignal.deviceUnlocked,
    'proximityCovered' => DeviceSignal.proximityCovered,
    'proximityUncovered' => DeviceSignal.proximityUncovered,
    _ => null,
  };
}

/// Thin wrapper over the platform channel. Every call is safe on platforms
/// without the native layer (tests, iOS for now).
class DeviceBridge {
  static const _methods = MethodChannel('lockin/device_use');
  static const _events = EventChannel('lockin/device_use/events');

  late final Stream<DeviceEvent> events = _events
      .receiveBroadcastStream()
      .map((e) {
        final m = Map<String, Object?>.from(e as Map);
        return DeviceEvent(
          m['signal'] as String,
          DateTime.fromMillisecondsSinceEpoch((m['t'] as num).toInt()),
        );
      })
      .handleError((Object _) {});

  Future<void> startSession({
    required DateTime startAt,
    DateTime? endAt,
    bool group = false,
  }) => _call('startSession', {
    'startAt': startAt.millisecondsSinceEpoch,
    'endAt': endAt?.millisecondsSinceEpoch ?? 0,
    'group': group,
  });

  Future<void> updateNotification(String title, String text) =>
      _call('updateNotification', {'title': title, 'text': text});

  /// Stops the service. With [doneTitle], leaves a dismissable "done" notification.
  Future<void> stopSession({String? doneTitle, String? doneText}) =>
      _call('stopSession', {'doneTitle': doneTitle, 'doneText': doneText});
  Future<void> openAppSettings() => _call('openAppSettings');

  Future<Map<String, Object?>> snapshot() async {
    try {
      return Map<String, Object?>.from(
        await _methods.invokeMethod<Map>('snapshot') ?? {},
      );
    } on MissingPluginException {
      return {};
    } on PlatformException {
      return {};
    }
  }

  Future<void> _call(String method, [Object? args]) async {
    try {
      await _methods.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // No native layer on this platform yet.
    } on PlatformException {
      // Never let a platform hiccup crash a session.
    }
  }
}

final deviceBridgeProvider = Provider<DeviceBridge>((ref) => DeviceBridge());

final deviceInfoProvider = FutureProvider<Map<String, Object?>>(
  (ref) => ref.read(deviceBridgeProvider).snapshot(),
);

/// Wall clock with an offset the debug tools can push forward.
class AppClock {
  Duration offset = Duration.zero;
  DateTime now() => DateTime.now().add(offset);
}

final clockProvider = Provider<AppClock>((ref) => AppClock());

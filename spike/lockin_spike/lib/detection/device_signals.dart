import 'package:flutter/services.dart';

import 'grace_tracker.dart';

/// One raw event from the native layer, with the native timestamp
/// (more accurate than Dart's receive time when the app was asleep).
class RawDeviceEvent {
  RawDeviceEvent(this.name, this.at, this.battery);
  final String name;
  final DateTime at;

  /// 0..1, or negative if unknown.
  final double battery;

  /// The tracker signal this maps to, or null for informational events.
  DeviceSignal? get signal => switch (name) {
        'appActive' => DeviceSignal.appActive,
        'appInactive' => DeviceSignal.appInactive,
        'proximityCovered' => DeviceSignal.proximityCovered,
        'proximityUncovered' => DeviceSignal.proximityUncovered,
        'deviceLocked' => DeviceSignal.deviceLocked,
        'deviceUnlocked' => DeviceSignal.deviceUnlocked,
        _ => null,
      };
}

class DeviceSignals {
  static const _methods = MethodChannel('lockin/device_use');
  static const _events = EventChannel('lockin/device_use/events');

  Stream<RawDeviceEvent> get events => _events.receiveBroadcastStream().map((e) {
        final m = Map<String, Object?>.from(e as Map);
        return RawDeviceEvent(
          m['signal'] as String,
          DateTime.fromMillisecondsSinceEpoch((m['t'] as num).toInt()),
          (m['battery'] as num?)?.toDouble() ?? -1,
        );
      });

  /// Returns false if face-down mode is unavailable (no proximity sensor,
  /// or no native layer on this platform yet).
  Future<bool> setFaceDownMode(bool on) async {
    try {
      return await _methods.invokeMethod<bool>('setFaceDownMode', on) ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Android: starts the foreground service ("Locked in" notification) that
  /// keeps detection running while the phone is locked. iOS: no-op.
  Future<void> startSession() => _call('startSession');
  Future<void> stopSession() => _call('stopSession');
  Future<void> openBatterySettings() => _call('openBatterySettings');

  Future<void> _call(String method) async {
    try {
      await _methods.invokeMethod<void>(method);
    } on MissingPluginException {
      // Not needed on this platform.
    }
  }

  Future<Map<String, Object?>> snapshot() async =>
      Map<String, Object?>.from(await _methods.invokeMethod<Map>('snapshot') ?? {});
}

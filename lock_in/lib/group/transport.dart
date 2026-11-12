import 'dart:async';

import 'package:flutter/services.dart';

import 'protocol.dart';

/// Peer id the joiner uses for its host.
const hostPeer = 'host';

sealed class TransportEvent {
  const TransportEvent();
}

class PeerConnected extends TransportEvent {
  const PeerConnected(this.peer);
  final String peer;
}

class PeerDisconnected extends TransportEvent {
  const PeerDisconnected(this.peer);
  final String peer;
}

class FrameReceived extends TransportEvent {
  const FrameReceived(this.peer, this.bytes);
  final String peer;
  final Uint8List bytes;
}

class TransportFailed extends TransportEvent {
  const TransportFailed(this.reason);

  /// One of: bluetooth_off, permission_denied, unsupported, advertise_failed,
  /// scan_failed, connect_failed, not_found.
  final String reason;
}

/// Moves encrypted frames between phones. Knows nothing about sessions.
abstract class GroupTransport {
  Stream<TransportEvent> get events;

  /// Host: advertise and accept connections for [code].
  Future<void> startHost(JoinCode code);

  /// Joiner: find and connect to the host for [code].
  Future<void> startJoin(JoinCode code);

  /// Host → a peer, or joiner → [hostPeer].
  Future<void> send(String peer, Uint8List frame);

  /// Host: stop accepting new phones (session started).
  Future<void> stopAdvertising();

  Future<void> disconnect(String peer);
  Future<void> stop();
}

/// Bluetooth LE via the Android layer (`LockInBle.kt`). Encryption happens
/// natively with the QR key; Dart only sees plaintext frames.
class NativeBleTransport implements GroupTransport {
  static const _methods = MethodChannel('lockin/ble');
  static const _eventsCh = EventChannel('lockin/ble/events');

  @override
  late final Stream<TransportEvent> events = _eventsCh
      .receiveBroadcastStream()
      .map<TransportEvent>((e) {
        final m = Map<String, Object?>.from(e as Map);
        final peer = (m['peer'] as String?) ?? hostPeer;
        return switch (m['type']) {
          'connected' => PeerConnected(peer),
          'disconnected' => PeerDisconnected(peer),
          'frame' => FrameReceived(peer, m['bytes']! as Uint8List),
          _ => TransportFailed((m['reason'] as String?) ?? 'unknown'),
        };
      })
      .handleError((Object _) {});

  Future<void> _call(String m, [Object? args]) async {
    try {
      await _methods.invokeMethod<void>(m, args);
    } on MissingPluginException {
      // No native BLE on this platform.
    } on PlatformException {
      // Reported through the events stream.
    }
  }

  @override
  Future<void> startHost(JoinCode code) =>
      _call('startHost', {'key': code.key});
  @override
  Future<void> startJoin(JoinCode code) =>
      _call('startJoin', {'key': code.key});
  @override
  Future<void> send(String peer, Uint8List frame) =>
      _call('send', {'peer': peer, 'bytes': frame});
  @override
  Future<void> stopAdvertising() => _call('stopAdvertising');
  @override
  Future<void> disconnect(String peer) => _call('disconnect', {'peer': peer});
  @override
  Future<void> stop() => _call('stop');

  /// Asks for Bluetooth permissions and to turn Bluetooth on. Returns a
  /// failure reason, or null when ready.
  static Future<String?> prepare() async {
    try {
      return await _methods.invokeMethod<String?>('prepare');
    } on MissingPluginException {
      return 'unsupported';
    } on PlatformException catch (e) {
      return e.code;
    }
  }

  /// Opens the offline QR scanner. Returns the raw text or null.
  static Future<String?> scanQr() async {
    try {
      return await _methods.invokeMethod<String?>('scanQr');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}

/// In-memory "radio" connecting fake transports, for tests and for the
/// simulated friends in test builds.
class FakeAir {
  final _hosts = <int, FakeTransport>{};
}

class FakeTransport implements GroupTransport {
  FakeTransport(this.air, this.name);
  final FakeAir air;

  /// This phone's peer id as seen by a host.
  final String name;
  final _events = StreamController<TransportEvent>.broadcast();
  final _peers = <String, FakeTransport>{};
  FakeTransport? _host;
  int? _hosting;
  bool _advertising = false;

  @override
  Stream<TransportEvent> get events => _events.stream;

  void _emit(TransportEvent e) => scheduleMicrotask(() {
    if (!_events.isClosed) _events.add(e);
  });

  @override
  Future<void> startHost(JoinCode code) async {
    _hosting = code.sessionId;
    _advertising = true;
    air._hosts[code.sessionId] = this;
  }

  @override
  Future<void> startJoin(JoinCode code) async {
    final h = air._hosts[code.sessionId];
    if (h == null || !h._advertising) {
      _emit(const TransportFailed('not_found'));
      return;
    }
    _host = h;
    h._peers[name] = this;
    h._emit(PeerConnected(name));
    _emit(const PeerConnected(hostPeer));
  }

  @override
  Future<void> send(String peer, Uint8List frame) async {
    final copy = Uint8List.fromList(frame);
    if (peer == hostPeer) {
      _host?._emit(FrameReceived(name, copy));
    } else {
      _peers[peer]?._emit(FrameReceived(hostPeer, copy));
    }
  }

  @override
  Future<void> stopAdvertising() async => _advertising = false;

  @override
  Future<void> disconnect(String peer) async {
    final p = _peers.remove(peer);
    if (p != null) {
      p._host = null;
      p._emit(const PeerDisconnected(hostPeer));
      _emit(PeerDisconnected(peer));
    }
  }

  @override
  Future<void> stop() async {
    for (final p in [..._peers.keys]) {
      await disconnect(p);
    }
    final h = _host;
    if (h != null) {
      h._peers.remove(name);
      h._emit(PeerDisconnected(name));
      _host = null;
    }
    if (_hosting != null) air._hosts.remove(_hosting);
  }
}

/// Routes to the native transport, plus fake peers (ids starting "sim:")
/// when test tools are on. Lets one phone host simulated friends.
class MixedTransport implements GroupTransport {
  MixedTransport(this.native, this.fake);
  final GroupTransport native;
  final FakeTransport fake;

  @override
  late final Stream<TransportEvent> events = StreamGroup2.merge([
    native.events,
    fake.events,
  ]);

  @override
  Future<void> startHost(JoinCode code) async {
    await fake.startHost(code);
    await native.startHost(code);
  }

  @override
  Future<void> startJoin(JoinCode code) => native.startJoin(code);

  @override
  Future<void> send(String peer, Uint8List frame) => peer.startsWith('sim:')
      ? fake.send(peer, frame)
      : native.send(peer, frame);

  @override
  Future<void> stopAdvertising() async {
    await fake.stopAdvertising();
    await native.stopAdvertising();
  }

  @override
  Future<void> disconnect(String peer) =>
      peer.startsWith('sim:') ? fake.disconnect(peer) : native.disconnect(peer);

  @override
  Future<void> stop() async {
    await fake.stop();
    await native.stop();
  }
}

/// Minimal stream merge (avoids a dependency).
abstract final class StreamGroup2 {
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    late StreamController<T> c;
    final subs = <StreamSubscription<T>>[];
    c = StreamController<T>.broadcast(
      onListen: () {
        for (final s in streams) {
          subs.add(s.listen(c.add, onError: (_) {}));
        }
      },
      onCancel: () {
        for (final s in subs) {
          s.cancel();
        }
        subs.clear();
      },
    );
    return c.stream;
  }
}

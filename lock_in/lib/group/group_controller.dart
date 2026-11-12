import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/nicknames.dart';
import '../catalog/vibes.dart';
import '../config.dart';
import '../platform/device_bridge.dart';
import '../session/session_controller.dart';
import '../storage/profile_store.dart';
import 'group_state.dart';
import 'protocol.dart';
import 'transport.dart';

/// A short-lived "Calm Otter cracked 💔" moment.
class Callout {
  const Callout(this.text, this.avatar, this.at, {this.good = false});
  final String text;
  final int avatar;
  final DateTime at;
  final bool good;
}

class CalloutsNotifier extends Notifier<List<Callout>> {
  @override
  List<Callout> build() => const [];
  void add(Callout c) =>
      state = [...state.where((x) => c.at.difference(x.at).inSeconds < 30), c];
}

final calloutsProvider = NotifierProvider<CalloutsNotifier, List<Callout>>(
  CalloutsNotifier.new,
);

/// Builds the transport. Tests override this with a [FakeTransport].
final groupTransportProvider = Provider<GroupTransport Function(GroupRole)>((
  ref,
) {
  final air = ref.watch(fakeAirProvider);
  return (role) => kDebugTools && role == GroupRole.host
      ? MixedTransport(NativeBleTransport(), FakeTransport(air, 'host'))
      : NativeBleTransport();
});

/// Asks for Bluetooth permission/power. Tests override to return null.
final blePrepareProvider = Provider<Future<String?> Function()>(
  (ref) => NativeBleTransport.prepare,
);

final fakeAirProvider = Provider<FakeAir>((ref) => FakeAir());

class GroupController extends Notifier<GroupView?> {
  GroupTransport? _t;
  StreamSubscription<TransportEvent>? _sub;
  Timer? _ping;
  Timer? _joinTimeout;
  final _peerIndex = <String, int>{};
  final _connected = <String>{};
  final _nonces = <int, int>{}; // memberIndex -> join nonce (for rejoin)
  int _mySeq = 0;
  int _myNonce = 0;
  Duration _clockOffset = Duration.zero; // host clock - local clock
  bool _sessionStarted = false;
  final sims = <SimFriend>[];

  @override
  GroupView? build() {
    ref.onDispose(_teardown);
    return null;
  }

  DateTime get _now => ref.read(clockProvider).now();

  // ---------------------------------------------------------------- host

  /// Start a squad. Returns a failure reason, or null.
  Future<String?> host() async {
    await leave();
    final profile = ref.read(profileProvider);
    if (profile == null) return 'no_profile';
    final problem = await ref.read(blePrepareProvider)();
    if (problem != null && !kDebugTools) return problem;
    final code = JoinCode.random(
      hostAvatar: profile.avatarId,
      hostNickname: profile.nicknameId,
    );
    _t = ref.read(groupTransportProvider)(GroupRole.host);
    _sub = _t!.events.listen(_onEvent);
    await _t!.startHost(code);
    final me = GroupMember(
      index: 0,
      avatar: profile.avatarId,
      nickname: profile.nicknameId,
      skin: profile.skinId,
      status: MemberStatus.settling,
      cracks: 0,
      seq: _mySeq,
      lockedSec: 0,
      clutches: 0,
      lastSeen: _now,
    );
    state = GroupView(
      role: GroupRole.host,
      code: code,
      config: SessionConfigMsg(
        code.sessionId,
        phase: GroupPhase.lobby,
        startUnix: 0,
        lengthMin: 25,
        vibe: Vibe.hangout.index,
        lastStanding: false,
        breaks: false,
        stake: 0,
        memberCount: 1,
      ),
      members: {0: me},
      myIndex: 0,
      bleProblem: problem,
    );
    return null;
  }

  void approve(String peer) {
    final v = state;
    if (v == null || !v.isHost) return;
    final p = v.pending.where((p) => p.peer == peer).firstOrNull;
    if (p == null) return;
    final idx = (v.members.keys.fold<int>(0, max)) + 1;
    if (idx > 250) return;
    _peerIndex[peer] = idx;
    _nonces[idx] = p.request.nonce;
    final m = GroupMember(
      index: idx,
      avatar: p.request.avatar,
      nickname: p.request.nickname,
      skin: p.request.skin,
      status: MemberStatus.settling,
      cracks: 0,
      seq: 0,
      lockedSec: 0,
      clutches: 0,
      lastSeen: _now,
    );
    final members = {...v.members, idx: m};
    final config = v.config.copyWith(memberCount: members.length);
    state = v.copyWith(
      members: members,
      config: config,
      pending: v.pending.where((x) => x.peer != peer).toList(),
    );
    _send(
      peer,
      JoinDecision(
        v.code.sessionId,
        nonce: p.request.nonce,
        accepted: true,
        memberIndex: idx,
      ),
    );
    _syncPeer(peer);
    _broadcast(m.toMsg(v.code.sessionId), except: peer);
    _broadcast(config);
    HapticFeedback.lightImpact();
  }

  void deny(String peer) {
    final v = state;
    if (v == null || !v.isHost) return;
    final p = v.pending.where((p) => p.peer == peer).firstOrNull;
    state = v.copyWith(
      pending: v.pending.where((x) => x.peer != peer).toList(),
    );
    if (p != null) {
      _send(
        peer,
        JoinDecision(
          v.code.sessionId,
          nonce: p.request.nonce,
          accepted: false,
          memberIndex: 0,
        ),
      );
    }
    Future<void>.delayed(
      const Duration(milliseconds: 500),
      () => _t?.disconnect(peer),
    );
  }

  /// Host: lobby options. Joiners see them live.
  void setOptions({
    int? lengthMin,
    Vibe? vibe,
    bool? lastStanding,
    bool? breaks,
    int? stake,
  }) {
    final v = state;
    if (v == null || !v.isHost || v.config.phase != GroupPhase.lobby) return;
    final c = v.config.copyWith(
      lengthMin: lengthMin,
      vibe: vibe?.index,
      lastStanding: lastStanding,
      breaks: breaks,
      stake: stake,
    );
    state = v.copyWith(config: c);
    _broadcast(c);
  }

  Future<void> start() async {
    final v = state;
    if (v == null || !v.isHost || v.config.phase != GroupPhase.lobby) return;
    for (final p in [...v.pending]) {
      deny(p.peer);
    }
    // Whole seconds, so every phone (which only gets seconds) starts in sync.
    final startUnix =
        _now.add(const Duration(seconds: 3)).millisecondsSinceEpoch ~/ 1000;
    final c = v.config.copyWith(
      phase: GroupPhase.running,
      startUnix: startUnix,
    );
    state = v.copyWith(config: c);
    await _t?.stopAdvertising();
    _broadcast(
      PingMsg(v.code.sessionId, hostUnix: _now.millisecondsSinceEpoch ~/ 1000),
    );
    _broadcast(c);
    _ping = Timer.periodic(const Duration(seconds: 15), (_) {
      final s = state;
      if (s != null) {
        _broadcast(
          PingMsg(
            s.code.sessionId,
            hostUnix: _now.millisecondsSinceEpoch ~/ 1000,
          ),
        );
      }
    });
    await _startMySession(
      c,
      DateTime.fromMillisecondsSinceEpoch(c.startUnix * 1000),
    );
  }

  // -------------------------------------------------------------- joiner

  /// Join from a scanned code. Returns a failure reason, or null.
  Future<String?> join(JoinCode code) async {
    await leave();
    final problem = await ref.read(blePrepareProvider)();
    if (problem != null) return problem;
    final profile = ref.read(profileProvider);
    if (profile == null) return 'no_profile';
    _myNonce = Random.secure().nextInt(0xffff);
    _t = ref.read(groupTransportProvider)(GroupRole.joiner);
    _sub = _t!.events.listen(_onEvent);
    state = GroupView(
      role: GroupRole.joiner,
      code: code,
      config: SessionConfigMsg(
        code.sessionId,
        phase: GroupPhase.lobby,
        startUnix: 0,
        lengthMin: 25,
        vibe: 0,
        lastStanding: false,
        breaks: false,
        stake: 0,
        memberCount: 1,
      ),
      members: const {},
      myIndex: null,
      stage: JoinStage.connecting,
    );
    _joinTimeout = Timer(const Duration(seconds: 25), () {
      final s = state;
      if (s != null && s.stage == JoinStage.connecting) {
        state = s.copyWith(stage: JoinStage.failed, failure: 'not_found');
        _t?.stop();
      }
    });
    await _t!.startJoin(code);
    return null;
  }

  // ------------------------------------------------------------- shared

  void _onEvent(TransportEvent e) {
    final v = state;
    if (v == null) return;
    switch (e) {
      case PeerConnected(:final peer):
        _connected.add(peer);
        if (!v.isHost && peer == hostPeer) {
          _joinTimeout?.cancel();
          final profile = ref.read(profileProvider)!;
          _send(
            hostPeer,
            JoinRequest(
              v.code.sessionId,
              nonce: _myNonce,
              avatar: profile.avatarId,
              nickname: profile.nicknameId,
              skin: profile.skinId,
            ),
          );
          if (v.stage == JoinStage.connecting) {
            state = v.copyWith(stage: JoinStage.waiting);
          }
          if (v.hostGone) state = (state ?? v).copyWith(hostGone: false);
        } else if (v.isHost) {
          // Must send a join request soon, or we hang up (no lurking).
          Timer(const Duration(seconds: 20), () {
            final s = state;
            if (s != null &&
                !_peerIndex.containsKey(peer) &&
                !s.pending.any((p) => p.peer == peer)) {
              _t?.disconnect(peer);
            }
          });
        }
      case PeerDisconnected(:final peer):
        _connected.remove(peer);
        if (v.isHost) {
          state = v.copyWith(
            pending: v.pending.where((p) => p.peer != peer).toList(),
          );
        } else if (peer == hostPeer) {
          if (v.stage == JoinStage.inGroup &&
              v.config.phase != GroupPhase.ended) {
            state = v.copyWith(hostGone: true);
          } else if (v.stage != JoinStage.inGroup) {
            state = v.copyWith(stage: JoinStage.failed, failure: 'host_left');
          }
        }
      case TransportFailed(:final reason):
        if (!v.isHost && v.stage != JoinStage.inGroup) {
          state = v.copyWith(stage: JoinStage.failed, failure: reason);
        } else if (v.isHost && v.bleProblem == null) {
          state = GroupView(
            role: v.role,
            code: v.code,
            config: v.config,
            members: v.members,
            myIndex: v.myIndex,
            pending: v.pending,
            bleProblem: reason,
          );
        }
      case FrameReceived(:final peer, :final bytes):
        GroupMsg msg;
        try {
          msg = GroupMsg.decode(bytes);
        } on FormatException {
          return;
        }
        if (msg.sessionId != v.code.sessionId) return;
        v.isHost ? _hostFrame(peer, msg) : _joinerFrame(msg);
    }
  }

  void _hostFrame(String peer, GroupMsg msg) {
    final v = state!;
    switch (msg) {
      case JoinRequest():
        // Rejoin after a dropout: same secret nonce → same seat.
        // Only if that seat's old link is really gone, so a replayed join
        // frame can't steal a seat from someone still connected.
        final seat = _nonces.entries
            .where((e) => e.value == msg.nonce)
            .firstOrNull
            ?.key;
        final seatLive = _peerIndex.entries.any(
          (e) => e.value == seat && _connected.contains(e.key),
        );
        if (seat != null &&
            !seatLive &&
            v.members[seat]?.avatar == msg.avatar &&
            v.members[seat]?.nickname == msg.nickname) {
          _peerIndex.removeWhere((_, i) => i == seat);
          _peerIndex[peer] = seat;
          _send(
            peer,
            JoinDecision(
              v.code.sessionId,
              nonce: msg.nonce,
              accepted: true,
              memberIndex: seat,
            ),
          );
          _syncPeer(peer);
          return;
        }
        if (v.config.phase != GroupPhase.lobby) {
          _send(
            peer,
            JoinDecision(
              v.code.sessionId,
              nonce: msg.nonce,
              accepted: false,
              memberIndex: 0,
            ),
          );
          return;
        }
        if (v.pending.any((p) => p.peer == peer) ||
            _peerIndex.containsKey(peer)) {
          return;
        }
        state = v.copyWith(pending: [...v.pending, PendingJoin(peer, msg)]);
        HapticFeedback.mediumImpact();
      case MemberStateMsg():
        if (_peerIndex[peer] != msg.index) return; // can't speak for others
        _applyMember(msg);
        _broadcast(msg, except: peer);
        _checkLastStanding();
      case LeaveMsg():
        if (_peerIndex[peer] != msg.index) return;
        final m = v.members[msg.index];
        if (m != null) {
          state = v.copyWith(
            members: {
              ...v.members,
              msg.index: m.copyWith(status: MemberStatus.left, seq: msg.seq),
            },
          );
          _broadcast(
            state!.members[msg.index]!.toMsg(v.code.sessionId),
            except: peer,
          );
          _callout(m, '${nicknameFor(m.nickname)} left 👋');
          _checkLastStanding();
        }
      default:
        break;
    }
  }

  void _joinerFrame(GroupMsg msg) {
    final v = state!;
    switch (msg) {
      case JoinDecision():
        if (msg.nonce != _myNonce) return;
        if (msg.accepted) {
          state = v.copyWith(
            myIndex: msg.memberIndex,
            stage: JoinStage.inGroup,
          );
          _reportMine(force: true);
        } else {
          state = v.copyWith(stage: JoinStage.denied);
          _t?.stop();
        }
      case SessionConfigMsg():
        state = v.copyWith(config: msg);
        if (msg.phase == GroupPhase.running &&
            !_sessionStarted &&
            v.myIndex != null) {
          final hostStart = DateTime.fromMillisecondsSinceEpoch(
            msg.startUnix * 1000,
          );
          _startMySession(msg, hostStart.subtract(_clockOffset));
        } else if (msg.phase == GroupPhase.ended) {
          _endedByHost(msg);
        }
      case MemberStateMsg():
        if (msg.index == v.myIndex) return;
        _applyMember(msg);
      case PingMsg():
        final local = _now;
        // Pings carry whole seconds, so only correct clearly-wrong clocks;
        // phones in the same room are almost always network-synced.
        final off = DateTime.fromMillisecondsSinceEpoch(msg.hostUnix * 1000)
            .difference(local);
        _clockOffset = off.abs() < const Duration(seconds: 2)
            ? Duration.zero
            : off;
        final host = v.members[0];
        if (host != null) {
          state = v.copyWith(members: {...v.members, 0: host.seen(local)});
        }
      default:
        break;
    }
  }

  void _applyMember(MemberStateMsg msg) {
    final v = state!;
    final old = v.members[msg.index];
    final merged = mergeMember(old, msg, _now)!;
    state = v.copyWith(members: {...v.members, msg.index: merged});
    if (old != null && merged.cracks > old.cracks) {
      _callout(merged, '${nicknameFor(merged.nickname)} cracked 💔');
      if (v.config.firstCrack == null && v.isHost) {
        final c = v.config.copyWith(firstCrack: merged.index);
        state = state!.copyWith(config: c);
        _broadcast(c);
      }
    } else if (old != null && merged.clutches > old.clutches) {
      _callout(
        merged,
        '${nicknameFor(merged.nickname)} CLUTCH 😮‍💨',
        good: true,
      );
    }
  }

  void _callout(GroupMember m, String text, {bool good = false}) {
    ref
        .read(calloutsProvider.notifier)
        .add(Callout(text, m.avatar, _now, good: good));
    if (!good) HapticFeedback.heavyImpact();
    ref
        .read(deviceBridgeProvider)
        .updateNotification(text, 'Phone down. Squad aura up.');
  }

  void _checkLastStanding() {
    final v = state;
    if (v == null ||
        !v.isHost ||
        !v.config.lastStanding ||
        v.config.phase != GroupPhase.running) {
      return;
    }
    final r = lastStandingResult(v.members.values);
    if (r == null) return;
    final c = v.config.copyWith(phase: GroupPhase.ended, winner: r.winner);
    state = v.copyWith(config: c);
    _broadcast(c);
    ref.read(sessionProvider.notifier).finish();
  }

  void _endedByHost(SessionConfigMsg c) {
    if (ref.read(sessionProvider) != null) {
      ref.read(sessionProvider.notifier).finish();
    }
  }

  Future<void> _startMySession(SessionConfigMsg c, DateTime startAt) async {
    _sessionStarted = true;
    await ref
        .read(sessionProvider.notifier)
        .start(
          c.lengthMin == 0 ? null : Duration(minutes: c.lengthMin),
          vibe: Vibe.values[c.vibe.clamp(0, Vibe.values.length - 1)],
          breaks: c.breaks,
          startAt: startAt,
          group: true,
        );
  }

  /// Called by the session controller whenever my state changes (and as a
  /// heartbeat). Sends only when something changed or [force] is set.
  void reportMine({
    required MemberStatus status,
    required int cracks,
    required int lockedSec,
    required int clutches,
    bool force = false,
  }) {
    final v = state;
    final idx = v?.myIndex;
    if (v == null || idx == null) return;
    final mine = v.members[idx];
    final changed =
        mine == null ||
        mine.status != status ||
        mine.cracks != cracks ||
        mine.clutches != clutches ||
        (lockedSec - mine.lockedSec).abs() >= 20;
    if (!changed && !force) return;
    _mySeq = (_mySeq + 1) & 0xffff;
    final profile = ref.read(profileProvider)!;
    final m = GroupMember(
      index: idx,
      avatar: profile.avatarId,
      nickname: profile.nicknameId,
      skin: profile.skinId,
      status: status,
      cracks: cracks,
      seq: _mySeq,
      lockedSec: lockedSec,
      clutches: clutches,
      lastSeen: _now,
    );
    state = v.copyWith(members: {...v.members, idx: m});
    final msg = m.toMsg(v.code.sessionId);
    if (v.isHost) {
      _broadcast(msg);
      if (cracks > (mine?.cracks ?? 0) && v.config.firstCrack == null) {
        final c = v.config.copyWith(firstCrack: idx);
        state = state!.copyWith(config: c);
        _broadcast(c);
      }
      _checkLastStanding();
    } else {
      _send(hostPeer, msg);
    }
  }

  void _reportMine({bool force = false}) {
    final s = ref.read(sessionProvider);
    reportMine(
      status: s == null ? MemberStatus.settling : s.memberStatus,
      cracks: s?.cracks ?? 0,
      lockedSec: s?.locked.inSeconds ?? 0,
      clutches: s?.engine.clutches ?? 0,
      force: force,
    );
  }

  /// My session finished (on time, early, or ended by the host).
  Future<void> mySessionFinished({required bool early}) async {
    final v = state;
    if (v == null) return;
    final idx = v.myIndex;
    if (idx != null) {
      final mine = v.members[idx];
      reportMine(
        status: early && !v.isHost ? MemberStatus.left : MemberStatus.finished,
        cracks: mine?.cracks ?? 0,
        lockedSec: mine?.lockedSec ?? 0,
        clutches: mine?.clutches ?? 0,
        force: true,
      );
    }
    if (v.isHost && state!.config.phase != GroupPhase.ended) {
      final c = state!.config.copyWith(phase: GroupPhase.ended);
      state = state!.copyWith(config: c);
      _broadcast(c);
    }
    // Give the last frames a moment to go out, then hang up.
    Timer(const Duration(seconds: 3), () => _t?.stop());
  }

  void _syncPeer(String peer) {
    final v = state!;
    _send(
      peer,
      PingMsg(v.code.sessionId, hostUnix: _now.millisecondsSinceEpoch ~/ 1000),
    );
    _send(peer, v.config);
    for (final m in v.members.values) {
      _send(peer, m.toMsg(v.code.sessionId));
    }
  }

  void _send(String peer, GroupMsg m) => _t?.send(peer, m.encode());

  void _broadcast(GroupMsg m, {String? except}) {
    final bytes = m.encode();
    for (final p in _peerIndex.keys) {
      if (p != except) _t?.send(p, Uint8List.fromList(bytes));
    }
  }

  /// Leave the squad (or close it, if hosting) and reset.
  Future<void> leave() async {
    final v = state;
    if (v != null &&
        v.myIndex != null &&
        v.config.phase == GroupPhase.lobby &&
        !v.isHost) {
      _send(
        hostPeer,
        LeaveMsg(
          v.code.sessionId,
          index: v.myIndex!,
          seq: (_mySeq + 1) & 0xffff,
        ),
      );
    }
    await _teardown();
    state = null;
  }

  Future<void> _teardown() async {
    _ping?.cancel();
    _joinTimeout?.cancel();
    for (final s in sims) {
      s.dispose();
    }
    sims.clear();
    await _sub?.cancel();
    _sub = null;
    await _t?.stop();
    _t = null;
    _peerIndex.clear();
    _connected.clear();
    _nonces.clear();
    _mySeq = 0;
    _sessionStarted = false;
    _clockOffset = Duration.zero;
  }

  // ------------------------------------------------- simulated friends (tests)

  /// Test builds: add a pretend friend who joins via the in-memory radio.
  Future<void> addSimFriend() async {
    final v = state;
    if (!kDebugTools || v == null || !v.isHost) return;
    final f = SimFriend(
      ref.read(fakeAirProvider),
      'sim:${sims.length + 1}',
      Random(),
    );
    sims.add(f);
    await f.join(v.code);
  }
}

final groupProvider = NotifierProvider<GroupController, GroupView?>(
  GroupController.new,
);

/// A pretend friend for one-phone testing. Speaks the real protocol over
/// the in-memory radio.
class SimFriend {
  SimFriend(FakeAir air, String id, this._rng)
    : t = FakeTransport(air, id),
      avatar = _rng.nextInt(8),
      nickname = randomNicknameId(_rng),
      skin = _rng.nextInt(10);
  final FakeTransport t;
  final Random _rng;
  final int avatar;
  final int nickname;
  final int skin;
  int? index;
  int _seq = 0;
  int _nonce = 0;
  int cracks = 0;
  int lockedSec = 0;
  MemberStatus status = MemberStatus.settling;
  JoinCode? _code;
  StreamSubscription<TransportEvent>? _sub;
  Timer? _beat;

  Future<void> join(JoinCode code) async {
    _code = code;
    _nonce = _rng.nextInt(0xffff);
    _sub = t.events.listen((e) {
      if (e is PeerConnected) {
        t.send(
          hostPeer,
          JoinRequest(
            code.sessionId,
            nonce: _nonce,
            avatar: avatar,
            nickname: nickname,
            skin: skin,
          ).encode(),
        );
      } else if (e is FrameReceived) {
        final m = GroupMsg.decode(e.bytes);
        if (m is JoinDecision && m.nonce == _nonce && m.accepted) {
          index = m.memberIndex;
        }
        if (m is SessionConfigMsg &&
            m.phase == GroupPhase.running &&
            status == MemberStatus.settling) {
          Timer(const Duration(seconds: 4), () => set(MemberStatus.locked));
          _beat = Timer.periodic(const Duration(seconds: 15), (_) {
            if (status == MemberStatus.locked) lockedSec += 15;
            _send();
          });
        }
      }
    });
    await t.startJoin(code);
  }

  void set(MemberStatus s) {
    if (s == MemberStatus.cracked && status != MemberStatus.cracked) cracks++;
    status = s;
    _send();
  }

  void _send() {
    final i = index, c = _code;
    if (i == null || c == null) return;
    _seq++;
    t.send(
      hostPeer,
      MemberStateMsg(
        c.sessionId,
        index: i,
        avatar: avatar,
        nickname: nickname,
        skin: skin,
        status: status,
        cracks: cracks,
        seq: _seq,
        lockedSec: lockedSec,
      ).encode(),
    );
  }

  void dispose() {
    _beat?.cancel();
    _sub?.cancel();
    t.stop();
  }
}

/// Lock In group protocol v1.
///
/// Phones exchange only: session id, member index, avatar/nickname/skin IDs
/// from fixed catalogs, status, counters and times. No free text, ever.
/// Frames are tiny little-endian binaries. The native layer encrypts every
/// frame with AES-GCM under a key that only exists in the host's QR code.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

const protocolVersion = 1;

enum MsgType { joinRequest, joinDecision, config, memberState, leave, ping }

/// Wire values for MsgType (1-based, low nibble of byte 0).
const _typeCodes = {
  MsgType.joinRequest: 1,
  MsgType.joinDecision: 2,
  MsgType.config: 3,
  MsgType.memberState: 4,
  MsgType.leave: 5,
  MsgType.ping: 6,
};

/// A member's status, as everyone else sees it.
enum MemberStatus {
  settling,
  locked,
  cracked,
  left,
  finished,
  up,
  onBreak,
  pass,
}

enum GroupPhase { lobby, running, ended }

sealed class GroupMsg {
  const GroupMsg(this.sessionId);
  final int sessionId;
  MsgType get type;
  void _write(ByteData b, int o);
  int get _len;

  Uint8List encode() {
    final bytes = Uint8List(1 + 4 + _len);
    final b = ByteData.sublistView(bytes);
    b.setUint8(0, (protocolVersion << 4) | _typeCodes[type]!);
    b.setUint32(1, sessionId, Endian.little);
    _write(b, 5);
    return bytes;
  }

  static GroupMsg decode(Uint8List bytes) {
    if (bytes.length < 5) throw const FormatException('frame too short');
    final b = ByteData.sublistView(bytes);
    final v = b.getUint8(0) >> 4;
    if (v != protocolVersion) throw FormatException('unsupported version $v');
    final code = b.getUint8(0) & 0x0f;
    final type = _typeCodes.entries
        .where((e) => e.value == code)
        .firstOrNull
        ?.key;
    if (type == null) throw FormatException('unknown type $code');
    final sid = b.getUint32(1, Endian.little);
    int u8(int o) => b.getUint8(o);
    int u16(int o) => b.getUint16(o, Endian.little);
    int u32(int o) => b.getUint32(o, Endian.little);
    void need(int n) {
      if (bytes.length != 5 + n) throw FormatException('bad length for $type');
    }

    switch (type) {
      case MsgType.joinRequest:
        need(6);
        return JoinRequest(
          sid,
          nonce: u16(5),
          avatar: u8(7),
          nickname: u16(8),
          skin: u8(10),
        );
      case MsgType.joinDecision:
        need(4);
        return JoinDecision(
          sid,
          nonce: u16(5),
          accepted: u8(7) == 1,
          memberIndex: u8(8),
        );
      case MsgType.config:
        need(13);
        final flags = u8(15);
        final winner = u8(17);
        return SessionConfigMsg(
          sid,
          phase: _enumAt(GroupPhase.values, u8(5)),
          startUnix: u32(6),
          lengthMin: u8(10),
          vibe: u8(11),
          lastStanding: flags & 1 == 1,
          breaks: flags & 2 == 2,
          stake: u8(12),
          firstCrack: u8(13) == 255 ? null : u8(13),
          memberCount: u8(14),
          winner: winner == 255 ? null : winner,
        );
      case MsgType.memberState:
        need(12);
        return MemberStateMsg(
          sid,
          index: u8(5),
          avatar: u8(6),
          nickname: u16(7),
          skin: u8(9),
          status: _enumAt(MemberStatus.values, u8(10)),
          cracks: u8(11),
          seq: u16(12),
          lockedSec: u16(14),
          clutches: u8(16),
        );
      case MsgType.leave:
        need(3);
        return LeaveMsg(sid, index: u8(5), seq: u16(6));
      case MsgType.ping:
        need(4);
        return PingMsg(sid, hostUnix: u32(5));
    }
  }

  static T _enumAt<T>(List<T> values, int i) {
    if (i >= values.length) throw FormatException('bad enum $i');
    return values[i];
  }
}

class JoinRequest extends GroupMsg {
  const JoinRequest(
    super.sessionId, {
    required this.nonce,
    required this.avatar,
    required this.nickname,
    required this.skin,
  });
  final int nonce;
  final int avatar;
  final int nickname;
  final int skin;
  @override
  MsgType get type => MsgType.joinRequest;
  @override
  int get _len => 6;
  @override
  void _write(ByteData b, int o) {
    b.setUint16(o, nonce, Endian.little);
    b.setUint8(o + 2, avatar);
    b.setUint16(o + 3, nickname, Endian.little);
    b.setUint8(o + 5, skin);
  }
}

class JoinDecision extends GroupMsg {
  const JoinDecision(
    super.sessionId, {
    required this.nonce,
    required this.accepted,
    required this.memberIndex,
  });
  final int nonce;
  final bool accepted;
  final int memberIndex;
  @override
  MsgType get type => MsgType.joinDecision;
  @override
  int get _len => 4;
  @override
  void _write(ByteData b, int o) {
    b.setUint16(o, nonce, Endian.little);
    b.setUint8(o + 2, accepted ? 1 : 0);
    b.setUint8(o + 3, memberIndex);
  }
}

class SessionConfigMsg extends GroupMsg {
  const SessionConfigMsg(
    super.sessionId, {
    required this.phase,
    required this.startUnix,
    required this.lengthMin,
    required this.vibe,
    required this.lastStanding,
    required this.breaks,
    required this.stake,
    required this.memberCount,
    this.firstCrack,
    this.winner,
  });
  final GroupPhase phase;

  /// When everyone's session starts (unix seconds), 0 in the lobby.
  final int startUnix;

  /// 0 = open-ended.
  final int lengthMin;
  final int vibe;
  final bool lastStanding;
  final bool breaks;
  final int stake;
  final int memberCount;
  final int? firstCrack;
  final int? winner;

  SessionConfigMsg copyWith({
    GroupPhase? phase,
    int? startUnix,
    int? lengthMin,
    int? vibe,
    bool? lastStanding,
    bool? breaks,
    int? stake,
    int? memberCount,
    int? firstCrack,
    int? winner,
  }) => SessionConfigMsg(
    sessionId,
    phase: phase ?? this.phase,
    startUnix: startUnix ?? this.startUnix,
    lengthMin: lengthMin ?? this.lengthMin,
    vibe: vibe ?? this.vibe,
    lastStanding: lastStanding ?? this.lastStanding,
    breaks: breaks ?? this.breaks,
    stake: stake ?? this.stake,
    memberCount: memberCount ?? this.memberCount,
    firstCrack: firstCrack ?? this.firstCrack,
    winner: winner ?? this.winner,
  );

  @override
  MsgType get type => MsgType.config;

  // Offsets from frame start: [5]=phase [6..9]=start [10]=len [11]=vibe
  // [12]=stake [13]=firstCrack [14]=count [15]=flags [16]=reserved [17]=winner
  @override
  int get _len => 13;
  @override
  void _write(ByteData b, int o) {
    b.setUint8(o, phase.index);
    b.setUint32(o + 1, startUnix, Endian.little);
    b.setUint8(o + 5, lengthMin);
    b.setUint8(o + 6, vibe);
    b.setUint8(o + 7, stake);
    b.setUint8(o + 8, firstCrack ?? 255);
    b.setUint8(o + 9, memberCount);
    b.setUint8(o + 10, (lastStanding ? 1 : 0) | (breaks ? 2 : 0));
    b.setUint8(o + 11, 0);
    b.setUint8(o + 12, winner ?? 255);
  }
}

class MemberStateMsg extends GroupMsg {
  const MemberStateMsg(
    super.sessionId, {
    required this.index,
    required this.avatar,
    required this.nickname,
    required this.skin,
    required this.status,
    required this.cracks,
    required this.seq,
    required this.lockedSec,
    this.clutches = 0,
  });
  final int index;
  final int avatar;
  final int nickname;
  final int skin;
  final MemberStatus status;
  final int cracks;

  /// Owned and incremented only by the member itself. Higher wins.
  final int seq;
  final int lockedSec;
  final int clutches;

  @override
  MsgType get type => MsgType.memberState;
  @override
  int get _len => 12;
  @override
  void _write(ByteData b, int o) {
    b.setUint8(o, index);
    b.setUint8(o + 1, avatar);
    b.setUint16(o + 2, nickname, Endian.little);
    b.setUint8(o + 4, skin);
    b.setUint8(o + 5, status.index);
    b.setUint8(o + 6, cracks.clamp(0, 255));
    b.setUint16(o + 7, seq & 0xffff, Endian.little);
    b.setUint16(o + 9, lockedSec.clamp(0, 0xffff), Endian.little);
    b.setUint8(o + 11, clutches.clamp(0, 255));
  }
}

class LeaveMsg extends GroupMsg {
  const LeaveMsg(super.sessionId, {required this.index, required this.seq});
  final int index;
  final int seq;
  @override
  MsgType get type => MsgType.leave;
  @override
  int get _len => 3;
  @override
  void _write(ByteData b, int o) {
    b.setUint8(o, index);
    b.setUint16(o + 1, seq & 0xffff, Endian.little);
  }
}

class PingMsg extends GroupMsg {
  const PingMsg(super.sessionId, {required this.hostUnix});
  final int hostUnix;
  @override
  MsgType get type => MsgType.ping;
  @override
  int get _len => 4;
  @override
  void _write(ByteData b, int o) => b.setUint32(o, hostUnix, Endian.little);
}

/// What the host's QR code holds. The key never leaves the room except as
/// pixels on the host's screen.
class JoinCode {
  const JoinCode({
    required this.sessionId,
    required this.key,
    required this.hostAvatar,
    required this.hostNickname,
  });
  final int sessionId;

  /// 16 random bytes: derives the encryption key and the per-session BLE id.
  final Uint8List key;
  final int hostAvatar;
  final int hostNickname;

  static JoinCode random({
    required int hostAvatar,
    required int hostNickname,
    Random? rng,
  }) {
    final r = rng ?? Random.secure();
    return JoinCode(
      sessionId: r.nextInt(1 << 32),
      key: Uint8List.fromList(List.generate(16, (_) => r.nextInt(256))),
      hostAvatar: hostAvatar,
      hostNickname: hostNickname,
    );
  }

  String encode() =>
      'lockin:1:${sessionId.toRadixString(16)}:${base64Url.encode(key).replaceAll('=', '')}:$hostAvatar:$hostNickname';

  /// Returns null for anything that isn't a valid Lock In code.
  static JoinCode? tryParse(String s) {
    final p = s.trim().split(':');
    if (p.length != 6 || p[0] != 'lockin' || p[1] != '1') return null;
    try {
      final sid = int.parse(p[2], radix: 16);
      final key = base64Url.decode(base64Url.normalize(p[3]));
      final av = int.parse(p[4]);
      final nick = int.parse(p[5]);
      if (key.length != 16 || sid < 0 || sid >= (1 << 32)) return null;
      return JoinCode(
        sessionId: sid,
        key: Uint8List.fromList(key),
        hostAvatar: av,
        hostNickname: nick,
      );
    } on FormatException {
      return null;
    }
  }
}

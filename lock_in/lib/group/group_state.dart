import 'protocol.dart';

/// One person in the squad, as this phone knows them.
class GroupMember {
  const GroupMember({
    required this.index,
    required this.avatar,
    required this.nickname,
    required this.skin,
    required this.status,
    required this.cracks,
    required this.seq,
    required this.lockedSec,
    required this.clutches,
    required this.lastSeen,
  });

  final int index;
  final int avatar;
  final int nickname;
  final int skin;
  final MemberStatus status;
  final int cracks;
  final int seq;
  final int lockedSec;
  final int clutches;
  final DateTime lastSeen;

  bool get gone => status == MemberStatus.left;

  GroupMember seen(DateTime t) => copyWith(lastSeen: t);

  GroupMember copyWith({
    MemberStatus? status,
    int? cracks,
    int? seq,
    int? lockedSec,
    int? clutches,
    DateTime? lastSeen,
  }) => GroupMember(
    index: index,
    avatar: avatar,
    nickname: nickname,
    skin: skin,
    status: status ?? this.status,
    cracks: cracks ?? this.cracks,
    seq: seq ?? this.seq,
    lockedSec: lockedSec ?? this.lockedSec,
    clutches: clutches ?? this.clutches,
    lastSeen: lastSeen ?? this.lastSeen,
  );

  MemberStateMsg toMsg(int sessionId) => MemberStateMsg(
    sessionId,
    index: index,
    avatar: avatar,
    nickname: nickname,
    skin: skin,
    status: status,
    cracks: cracks,
    seq: seq,
    lockedSec: lockedSec,
    clutches: clutches,
  );

  static GroupMember fromMsg(MemberStateMsg m, DateTime now) => GroupMember(
    index: m.index,
    avatar: m.avatar,
    nickname: m.nickname,
    skin: m.skin,
    status: m.status,
    cracks: m.cracks,
    seq: m.seq,
    lockedSec: m.lockedSec,
    clutches: m.clutches,
    lastSeen: now,
  );
}

/// 16-bit sequence comparison with wrap-around.
bool seqNewer(int incoming, int stored) {
  final d = (incoming - stored) & 0xffff;
  return d != 0 && d < 0x8000;
}

/// Apply a member's update. Only newer sequence numbers win, so relays,
/// duplicates and out-of-order delivery are harmless.
GroupMember? mergeMember(GroupMember? old, MemberStateMsg m, DateTime now) {
  if (old == null) return GroupMember.fromMsg(m, now);
  if (!seqNewer(m.seq, old.seq)) return old.seen(now);
  // Cracks only ever go up, even if a stale-but-newer message says less.
  final merged = GroupMember.fromMsg(m, now);
  return merged.cracks < old.cracks
      ? merged.copyWith(cracks: old.cracks)
      : merged;
}

/// No frame or link for this long = "away" (out of range), never "cracked".
const awayAfter = Duration(seconds: 60);

bool isAway(GroupMember m, DateTime now) =>
    !m.gone &&
    m.status != MemberStatus.finished &&
    now.difference(m.lastSeen) > awayAfter;

/// Last one standing: ends once at most one member still has 0 cracks.
/// Returns null while the game is still on.
({int? winner})? lastStandingResult(Iterable<GroupMember> members) {
  final active = members.where((m) => !m.gone).toList();
  if (active.length < 2) return null;
  final clean = active.where((m) => m.cracks == 0).toList();
  if (clean.length > 1) return null;
  return (winner: clean.isEmpty ? null : clean.single.index);
}

/// Everyone who stayed kept it clean → squad multiplier.
bool squadClean(Iterable<GroupMember> members) {
  final active = members.where((m) => !m.gone).toList();
  return active.length >= 2 && active.every((m) => m.cracks == 0);
}

enum GroupRole { host, joiner }

enum JoinStage { connecting, waiting, inGroup, denied, failed }

class PendingJoin {
  const PendingJoin(this.peer, this.request);
  final String peer;
  final JoinRequest request;
}

/// Everything the group screens need.
class GroupView {
  const GroupView({
    required this.role,
    required this.code,
    required this.config,
    required this.members,
    required this.myIndex,
    this.pending = const [],
    this.stage = JoinStage.inGroup,
    this.failure,
    this.hostGone = false,
    this.bleProblem,
  });

  final GroupRole role;
  final JoinCode code;
  final SessionConfigMsg config;
  final Map<int, GroupMember> members;
  final int? myIndex;
  final List<PendingJoin> pending;
  final JoinStage stage;
  final String? failure;
  final bool hostGone;

  /// Host only: Bluetooth couldn't start (simulated friends still work in
  /// test builds).
  final String? bleProblem;

  bool get isHost => role == GroupRole.host;
  List<GroupMember> get sorted =>
      members.values.toList()..sort((a, b) => a.index.compareTo(b.index));
  List<GroupMember> get others =>
      sorted.where((m) => m.index != myIndex).toList();

  GroupView copyWith({
    SessionConfigMsg? config,
    Map<int, GroupMember>? members,
    int? myIndex,
    List<PendingJoin>? pending,
    JoinStage? stage,
    String? failure,
    bool? hostGone,
  }) => GroupView(
    role: role,
    code: code,
    config: config ?? this.config,
    members: members ?? this.members,
    myIndex: myIndex ?? this.myIndex,
    pending: pending ?? this.pending,
    stage: stage ?? this.stage,
    failure: failure ?? this.failure,
    hostGone: hostGone ?? this.hostGone,
    bleProblem: bleProblem,
  );
}

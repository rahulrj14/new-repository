import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/detection/grace_tracker.dart';
import 'package:lock_in/group/group_controller.dart';
import 'package:lock_in/group/group_state.dart';
import 'package:lock_in/group/protocol.dart';
import 'package:lock_in/group/transport.dart';
import 'package:lock_in/platform/device_bridge.dart';
import 'package:lock_in/session/session_controller.dart';
import 'package:lock_in/storage/db.dart';
import 'package:lock_in/storage/profile_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('codec', () {
    T roundTrip<T extends GroupMsg>(T m) => GroupMsg.decode(m.encode()) as T;

    test('every message type survives encode/decode', () {
      final j = roundTrip(
        const JoinRequest(7, nonce: 513, avatar: 3, nickname: 4000, skin: 9),
      );
      expect((j.nonce, j.avatar, j.nickname, j.skin), (513, 3, 4000, 9));
      final d = roundTrip(
        const JoinDecision(7, nonce: 1, accepted: true, memberIndex: 4),
      );
      expect((d.accepted, d.memberIndex), (true, 4));
      final c = roundTrip(
        const SessionConfigMsg(
          7,
          phase: GroupPhase.running,
          startUnix: 1794500000,
          lengthMin: 50,
          vibe: 2,
          lastStanding: true,
          breaks: true,
          stake: 3,
          memberCount: 4,
          firstCrack: 2,
          winner: 1,
        ),
      );
      expect(
        (
          c.phase,
          c.startUnix,
          c.lengthMin,
          c.vibe,
          c.lastStanding,
          c.breaks,
          c.stake,
          c.memberCount,
          c.firstCrack,
          c.winner,
        ),
        (GroupPhase.running, 1794500000, 50, 2, true, true, 3, 4, 2, 1),
      );
      final c2 = roundTrip(
        const SessionConfigMsg(
          7,
          phase: GroupPhase.lobby,
          startUnix: 0,
          lengthMin: 0,
          vibe: 0,
          lastStanding: false,
          breaks: false,
          stake: 0,
          memberCount: 1,
        ),
      );
      expect((c2.firstCrack, c2.winner, c2.lastStanding), (null, null, false));
      final m = roundTrip(
        const MemberStateMsg(
          7,
          index: 2,
          avatar: 1,
          nickname: 77,
          skin: 5,
          status: MemberStatus.cracked,
          cracks: 3,
          seq: 65535,
          lockedSec: 3000,
          clutches: 2,
        ),
      );
      expect(
        (m.index, m.status, m.cracks, m.seq, m.lockedSec, m.clutches),
        (2, MemberStatus.cracked, 3, 65535, 3000, 2),
      );
      expect(roundTrip(const LeaveMsg(7, index: 3, seq: 9)).index, 3);
      expect(roundTrip(const PingMsg(7, hostUnix: 123)).hostUnix, 123);
    });

    test('all frames fit comfortably in one BLE packet (after encryption)', () {
      final biggest = const SessionConfigMsg(
        1,
        phase: GroupPhase.lobby,
        startUnix: 0,
        lengthMin: 0,
        vibe: 0,
        lastStanding: false,
        breaks: false,
        stake: 0,
        memberCount: 1,
      ).encode().length;
      // + 12-byte nonce + 16-byte GCM tag must fit a 185-byte MTU payload.
      expect(biggest + 28, lessThan(182));
    });

    test('rejects junk', () {
      expect(
        () => GroupMsg.decode(Uint8List.fromList([0x21, 0, 0, 0, 0])),
        throwsFormatException,
      ); // v2
      expect(
        () => GroupMsg.decode(Uint8List.fromList([0x1f, 0, 0, 0, 0])),
        throwsFormatException,
      ); // type 15
      expect(
        () => GroupMsg.decode(Uint8List.fromList([0x14, 0, 0, 0, 0, 1])),
        throwsFormatException,
      ); // short
    });

    test('join code', () {
      final c = JoinCode.random(hostAvatar: 3, hostNickname: 1234);
      final p = JoinCode.tryParse(c.encode())!;
      expect(
        (p.sessionId, p.hostAvatar, p.hostNickname),
        (c.sessionId, 3, 1234),
      );
      expect(p.key, c.key);
      expect(JoinCode.tryParse('https://example.com'), isNull);
      expect(JoinCode.tryParse('lockin:1:zz:abc:1:2'), isNull);
    });
  });

  group('merge rules', () {
    final t = DateTime(2026);
    MemberStateMsg ms(int seq, int cracks) => MemberStateMsg(
      1,
      index: 1,
      avatar: 0,
      nickname: 0,
      skin: 0,
      status: MemberStatus.locked,
      cracks: cracks,
      seq: seq,
      lockedSec: 0,
    );

    test('newer seq wins, older is ignored, wrap-around works', () {
      var m = mergeMember(null, ms(10, 0), t)!;
      m = mergeMember(m, ms(9, 5), t)!;
      expect(m.seq, 10);
      m = mergeMember(m, ms(11, 1), t)!;
      expect(m.cracks, 1);
      m = mergeMember(m.copyWith(seq: 65535), ms(0, 2), t)!;
      expect(m.cracks, 2);
    });

    test('cracks never go down', () {
      final a = mergeMember(null, ms(1, 3), t)!;
      expect(mergeMember(a, ms(2, 1), t)!.cracks, 3);
    });

    GroupMember gm(int i, int cracks, {bool left = false}) => GroupMember(
      index: i,
      avatar: 0,
      nickname: 0,
      skin: 0,
      status: left ? MemberStatus.left : MemberStatus.locked,
      cracks: cracks,
      seq: 0,
      lockedSec: 0,
      clutches: 0,
      lastSeen: t,
    );

    test('last one standing', () {
      expect(lastStandingResult([gm(0, 0), gm(1, 0)]), isNull);
      expect(lastStandingResult([gm(0, 0), gm(1, 1)])!.winner, 0);
      expect(lastStandingResult([gm(0, 1), gm(1, 2)])!.winner, isNull);
      expect(
        lastStandingResult([gm(0, 0), gm(1, 0, left: true)]),
        isNull,
        reason: 'needs 2 active',
      );
    });

    test('squad clean', () {
      expect(squadClean([gm(0, 0), gm(1, 0)]), isTrue);
      expect(squadClean([gm(0, 0), gm(1, 1)]), isFalse);
      expect(squadClean([gm(0, 0)]), isFalse);
      expect(isAway(gm(0, 0), t.add(const Duration(seconds: 61))), isTrue);
    });
  });

  group('two phones, fake radio', () {
    late FakeAir air;
    Future<ProviderContainer> phone(String name, int avatar) async {
      SharedPreferences.setMockInitialValues({
        'avatarId': avatar,
        'nicknameId': avatar * 10,
        'skinId': 0,
      });
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          dbProvider.overrideWithValue(AppDatabase(NativeDatabase.memory())),
          groupTransportProvider.overrideWithValue(
            (_) => FakeTransport(air, name),
          ),
          blePrepareProvider.overrideWithValue(() async => null),
          clockProvider.overrideWithValue(AppClock()),
        ],
      );
      c.read(profileProvider);
      await c.read(progressProvider.future);
      return c;
    }

    Future<void> settle([int ms = 50]) =>
        Future<void>.delayed(Duration(milliseconds: ms));

    test('host approves, everyone starts together, crack → last one standing ends it', () async {
      air = FakeAir();
      final host = await phone('A', 1);
      final guest = await phone('B', 2);
      addTearDown(host.dispose);
      addTearDown(guest.dispose);

      expect(await host.read(groupProvider.notifier).host(), isNull);
      final code = host.read(groupProvider)!.code;
      expect(await guest.read(groupProvider.notifier).join(code), isNull);
      await settle();

      // Nobody gets in without the host's tap.
      expect(guest.read(groupProvider)!.stage, JoinStage.waiting);
      final pending = host.read(groupProvider)!.pending;
      expect(pending, hasLength(1));
      expect(pending.single.request.avatar, 2);

      host.read(groupProvider.notifier).approve(pending.single.peer);
      await settle();
      expect(guest.read(groupProvider)!.stage, JoinStage.inGroup);
      expect(guest.read(groupProvider)!.myIndex, 1);
      expect(guest.read(groupProvider)!.members.keys, containsAll([0, 1]));

      host
          .read(groupProvider.notifier)
          .setOptions(lengthMin: 25, lastStanding: true, stake: 1);
      await settle();
      expect(guest.read(groupProvider)!.config.lastStanding, isTrue);
      expect(guest.read(groupProvider)!.config.stake, 1);

      await host.read(groupProvider.notifier).start();
      await settle();
      expect(host.read(sessionProvider), isNotNull);
      expect(guest.read(sessionProvider), isNotNull);
      expect(
        guest.read(sessionProvider)!.engine.startedAt,
        host.read(sessionProvider)!.engine.startedAt,
      );

      // Both lock, then the guest unlocks and cracks.
      for (final c in [host, guest]) {
        c.read(sessionProvider.notifier).fake(DeviceSignal.deviceLocked);
        c.read(sessionProvider.notifier).warp(const Duration(minutes: 2));
      }
      await settle();
      guest.read(sessionProvider.notifier).fake(DeviceSignal.deviceUnlocked);
      guest.read(sessionProvider.notifier).warp(const Duration(seconds: 11));
      await settle(300);

      // Host saw the crack, ended last-one-standing, everyone finished.
      expect(
        host.read(calloutsProvider).map((c) => c.text).join(),
        contains('cracked'),
      );
      expect(host.read(sessionProvider), isNull);
      expect(guest.read(sessionProvider), isNull);
      final hr = host.read(lastResultProvider)!;
      final gr = guest.read(lastResultProvider)!;
      expect(hr.squad!.iWon, isTrue);
      expect(gr.squad!.iWon, isFalse);
      expect(hr.squad!.firstCrack, 1);
      expect(hr.squad!.clean, isFalse);
      expect(hr.squad!.members, hasLength(2));
    });

    test('denied joiner never sees the squad', () async {
      air = FakeAir();
      final host = await phone('A', 1);
      final guest = await phone('B', 2);
      addTearDown(host.dispose);
      addTearDown(guest.dispose);
      await host.read(groupProvider.notifier).host();
      await guest
          .read(groupProvider.notifier)
          .join(host.read(groupProvider)!.code);
      await settle();
      host
          .read(groupProvider.notifier)
          .deny(host.read(groupProvider)!.pending.single.peer);
      await settle(700);
      expect(guest.read(groupProvider)!.stage, JoinStage.denied);
      expect(guest.read(groupProvider)!.members, isEmpty);
    });

    test(
      'a frame for another member from the wrong phone is ignored',
      () async {
        air = FakeAir();
        final host = await phone('A', 1);
        await host.read(groupProvider.notifier).host();
        final code = host.read(groupProvider)!.code;
        final evil = FakeTransport(air, 'evil');
        await evil.startJoin(code);
        await settle();
        // Pretend to be the host (index 0) with a crack.
        await evil.send(
          hostPeer,
          const MemberStateMsg(
            0,
            index: 0,
            avatar: 1,
            nickname: 10,
            skin: 0,
            status: MemberStatus.cracked,
            cracks: 9,
            seq: 999,
            lockedSec: 0,
          ).encode(),
        );
        await settle();
        expect(host.read(groupProvider)!.members[0]!.cracks, 0);
        host.dispose();
      },
    );
  });
}

# Lock In: architecture proposal (for approval)

Status: **draft, waiting for approval.** I haven't written any feature code yet.
This covers the folder structure, data model, message protocol and the technical spike plan. It also lists the platform limits we need to accept before building.

---

## 0. Feasibility in brief

| Area | Android | iOS |
|---|---|---|
| BLE link stays up with the phone locked | Yes, with a foreground service (`connectedDevice` type). Some OEM battery killers (Xiaomi, Oppo, some Samsung builds) can still kill it, and we'll need a "disable battery optimisation" help screen. | Yes, **for connections made while the app was in the foreground**. The `bluetooth-central` and `bluetooth-peripheral` modes keep links alive, and the app is woken briefly (about 10 s) on BLE events. |
| Discovering new peers while locked | Yes | **Weak.** In the background, iOS moves the service UUID into an Apple "overflow area" that only iOS scanners looking for that exact UUID can see. Android can't reliably see it, and local name and service data aren't sent. **So joining happens in the foreground**, which is natural, because everyone is in the app when they join. |
| Periodic timers while locked | Yes (foreground service) | **No.** A suspended app runs no timers and only wakes on BLE events. |
| Unlock detection | `ACTION_USER_PRESENT`, registered dynamically from the foreground service. Reliable and instant. | **No public API wakes a suspended app on unlock.** The app can only *check* `isProtectedDataAvailable` (needs a passcode; turns false about 10 s after lock) when something else wakes it. Details in §5. |
| Host handover with all phones locked | Works if the new host is Android | Fragile. A backgrounded iOS phone that becomes host advertises only in the overflow area, so Android members may not find it. |

**Key design choice this leads to:** each phone is **authoritative for its own** lock, crack and aura state and records it locally, whatever the connectivity. Bluetooth only syncs the *live view*. If the link drops, nobody loses aura or gets falsely cracked. The live view degrades to "away", and phones reconcile when they reconnect.

---

## 1. Folder structure

```
lib/
  main.dart                  # release entrypoint (no debug menu)
  main_debug.dart            # debug entrypoint: wraps app with debug menu + fake overrides
  app.dart                   # MaterialApp.router, theme, ProviderScope
  router.dart                # go_router routes

  bluetooth/                 # transport only: bytes in, bytes out. No session logic.
    ble_transport.dart       # abstract BleTransport (host/joiner roles, streams of frames + link events)
    native_ble_transport.dart# implementation via platform channel (Pigeon) + flutter_blue_plus
    gatt_ids.dart            # service/characteristic UUIDs
    advert_codec.dart        # encode/decode advertised local name ("LI1" + base32 payload)
    fake_transport.dart      # in-memory multi-peer transport for tests + debug menu

  session/
    protocol/
      messages.dart          # sealed classes for each message type
      codec.dart             # binary encode/decode, versioned
    model/
      member.dart            # Member, MemberState, Presence
      session_snapshot.dart  # immutable full session view
    reducer.dart             # PURE: (snapshot, event) -> snapshot. All merging rules live here.
    host_controller.dart     # approvals, relay, roster, advertising lifecycle
    joiner_controller.dart   # join request, reconnect, handover takeover
    handover.dart            # host election (pure) + takeover procedure
    session_clock.dart       # host-anchored clock, offset estimation
    session_providers.dart   # Riverpod wiring

  detection/
    unlock_detector.dart     # abstract: Stream<DeviceUseEvent> (unlocked / relocked / screenTimeThreshold)
    android_unlock_detector.dart
    ios_unlock_detector.dart
    grace_window.dart        # PURE: 10 s unlock grace -> crack decision
    fake_unlock_detector.dart

  progression/               # PURE rules, no I/O (my addition to your layer list)
    aura_rules.dart          # points, multipliers, daily cap
    streak_rules.dart        # qualifying day, freezes
    levels.dart              # aura thresholds -> level
    skins_catalog.dart       # static skin list + unlock conditions

  storage/
    db.dart                  # drift database
    tables.dart
    repositories/            # SessionRepo, ProgressRepo, SkinRepo, PurchaseRepo
    settings.dart            # shared_preferences wrapper

  platform/                  # thin Dart side of native features (my addition)
    foreground_service.dart  # Android "Locked in" notification service
    live_activity.dart       # iOS Live Activity (phase 5)
    haptics.dart

  share/
    share_card.dart          # 1080x1920 widget
    card_renderer.dart       # RepaintBoundary -> PNG -> share_plus

  catalog/
    avatars.dart             # avatar IDs -> assets
    nicknames.dart           # fixed adjective + animal word lists -> nicknameId

  ui/
    theme/ widgets/ onboarding/ home/ lobby/ session/ results/ profile/ solo/

  debug/                     # only imported from main_debug.dart -> tree-shaken from release
    debug_menu.dart          # fake peers, fake unlocks, time warp

android/app/src/main/kotlin/.../
  LockInPeripheral.kt        # BluetoothLeAdvertiser + BluetoothGattServer
  LockInService.kt           # foreground service (connectedDevice) hosting BLE + unlock receiver
  UnlockReceiver.kt          # ACTION_USER_PRESENT / SCREEN_OFF
ios/Runner/
  LockInPeripheral.swift     # CBPeripheralManager with state restoration
  DeviceUseMonitor.swift     # protected-data checks, lifecycle
pigeons/lockin_api.dart      # Pigeon definitions (typed platform channels)

test/
  session/codec_test.dart  session/reducer_test.dart  session/handover_test.dart
  detection/grace_window_test.dart  progression/*_test.dart
integration_test/
  session_lifecycle_test.dart   # 4 fake peers via FakeTransport: join, approve, crack, host leaves, end

spike/lockin_spike/          # throwaway Flutter app for step 1 (see §6)
```

The debug menu exists only in `main_debug.dart`. `flutter build --release -t lib/main.dart` never imports `lib/debug/`, so it isn't compiled in. There's also a CI check that greps the release build entrypoint graph.

---

## 2. Message protocol

### 2.1 GATT layout (host = peripheral)

- **Service** `LOCKIN_SERVICE_UUID`, a random v4 UUID we generate once.
- **`control`** characteristic: *write with response*, joiner to host.
- **`events`** characteristic: *notify*, host to joiner. The host sends notifications **only to approved centrals**, addressed per device on both platforms, so an unapproved connection receives nothing.
- No BLE pairing or bonding (it triggers OS dialogs). Traffic is therefore readable by a BLE sniffer in the room. That's acceptable only because the payloads contain no personal data (see §2.4).

### 2.2 Advertising

iOS peripherals can't advertise service data or manufacturer data, only service UUIDs and a local name. So the host advertises:

- the service UUID, and
- the local name `LI1` + base32(sessionId[4], hostAvatarId[1], hostNicknameId[2]), which is 15 chars.

Joiners on the "Join" screen list nearby sessions as the host's avatar plus nickname ("Calm Otter's session"). The host advertises **only while the lobby is open**. Once the session starts, advertising stops and the session is closed to new joiners. A host may tap "Let more people in" to reopen it.

### 2.3 Frames

Binary, little-endian. The target is **≤ 20 bytes per frame**, so everything fits the default ATT MTU of 23 with no MTU negotiation (which is flaky on some Androids).

Byte 0 is `version (high nibble) | type (low nibble)`. v1 = `0x1`.

| Type | Name | Direction | Layout after byte 0 | Size |
|---|---|---|---|---|
| 0x1 | `JOIN_REQUEST` | J→H | sessionId u32, nonce u16, avatarId u8, nicknameId u16 | 10 |
| 0x2 | `JOIN_DECISION` | H→J | sessionId u32, nonce u16, accepted u8, memberIndex u8, rejoinKey u32 | 13 |
| 0x3 | `SESSION_CONFIG` | H→J | sessionId u32, startUnix u32, lengthMin u8 (0 = open-ended), hostIndex u8, phase u8 (lobby/running/ended) | 12 |
| 0x4 | `MEMBER_STATE` | both | sessionId u32, memberIndex u8, avatarId u8, nicknameId u16, state u8, crackCount u8, seq u16, ts u32 | 17 |
| 0x5 | `LEAVE` | J→H | sessionId u32, memberIndex u8, seq u16 | 8 |
| 0x6 | `PING` | H→J | sessionId u32, hostUnix u32 | 9 |
| 0x7 | `HANDOVER` | H→J | sessionId u32, newHostIndex u8 | 6 |
| 0x8 | `REJOIN` | J→H | sessionId u32, memberIndex u8, rejoinKey u32 | 10 |

- `state`: 0 joined, 1 locked, 2 cracked, 3 left, 4 finished.
- **`memberIndex`** is assigned by the host in join order (0 = original host). It doubles as the handover priority ("earliest remaining joiner").
- **`seq`** is per member and only ever incremented by that member. Receivers keep the highest `seq` per member. That one rule makes relays idempotent and order-independent.
- **`ts`** is the sender's unix seconds, used for display only. Ordering never uses it, because clocks differ.
- Presence (`present` / `away`) is **not sent**. Each phone derives it locally: a member is away after 60 s with no link and no frame (link supervision events, plus `PING` every 15 s from an Android host).
- Unknown `version` or `type` gets a polite "Update Lock In to join this session" message. Decoders reject frames with a wrong length or an unknown enum value.

### 2.4 Fields beyond your list (please approve)

Your spec lists session ID, avatar ID, nickname ID, state and timestamp. I'm proposing these additions. None of them is free text, identifying or persistent across sessions:

- `memberIndex` (u8), `seq` (u16), `crackCount` (u8): needed for merging and handover.
- `startUnix`, `lengthMin`, `phase`, `hostIndex`: the shared timer.
- `nonce` (random per join attempt) and `rejoinKey` (random per session, given only to approved members): so a stranger can't silently rejoin as someone else after a dropout.

**Nothing persistent is ever sent.** No device ID, no install ID, no account. sessionId and rejoinKey are fresh random numbers each session.

### 2.5 Merging rules (all in `reducer.dart`, unit-tested)

1. Frames for a different `sessionId` are dropped.
2. `MEMBER_STATE` is applied only if `seq` is greater than the stored seq for that member.
3. The host accepts `MEMBER_STATE` for memberIndex *i* only from the connection that is bound to *i*. This prevents spoofing another member.
4. The host relays every accepted state to all approved members, and sends the full roster to a newly approved or rejoining member.
5. `left` and `finished` are terminal for that member in this session.
6. `cracked` → `locked` is allowed (you can recover by relocking). `crackCount` only increases.

### 2.6 Host handover

- When the host link drops, each joiner waits 10 s (to cover brief blips), then elects the **lowest `memberIndex` among members not `left`** as the new host. The election is a pure function, so everyone reaches the same answer.
- The new host advertises the same sessionId. Others scan, reconnect and send `REJOIN`, which is auto-accepted if the key matches.
- **Caveat:** if the new host is an iPhone that is locked, its background advertising is overflow-area only and Android members may not find it (§0). To reduce this, I'm proposing a tiebreak: **prefer the earliest-joined Android member, then the earliest joiner.** This deviates from your "earliest remaining joiner" rule, so please approve or reject.
- If handover fails, every phone keeps tracking itself locally (see the key design choice above) and the live view shows the others as "away".

---

## 3. Data model (drift, on device only)

```
profile            (id=1, avatarId, nicknameId, equippedSkinId, createdAt)
sessions           (id PK, sessionId u32, mode [solo|host|joiner], startedAt, plannedMin?,
                    endedAt, lockedSeconds, crackCount, groupSize, groupCrackFree bool,
                    auraEarned, endReason [completed|ended_early|left])
session_members    (sessionRowId FK, memberIndex, avatarId, nicknameId, finalState, crackCount)
                    -- for the results screen/share card; contains only catalog IDs
aura_ledger        (id, localDate, sessionRowId?, amount, reason [locked|group_bonus|streak|cap_trim])
daily_activity     (localDate PK, lockedSeconds, qualified bool, freezeUsed bool)
streak_state       (id=1, current, longest, freezesAvailable, lastQualifiedDate)
skins              (skinId PK, unlockedAt, source [level|streak|purchase])
purchases          (productId, transactionId PK, purchaseDate, status)  -- on-device receipts
```

**Shared preferences:** onboarding done, sound on/off, haptics on/off, reduce motion override, preferred session length.

**Starting rules** (live in `progression/`, all easy to tune):

- **Aura:** 1 per locked minute. ×1.5 group bonus if nobody cracked. A crack costs 5 and ends your bonus. Daily cap of 300; anything above it is recorded as `cap_trim` so the UI can say "you've maxed today, nice."
- **Streak:** a day qualifies with ≥ 25 locked minutes. You earn 1 freeze per 7-day streak (hold max 2), and a freeze is applied automatically to one missed day.
- **No push notifications at all in v1.** The only notification is Android's required "Locked in" foreground notification during a session.

---

## 4. Dependencies (each checked for phoning home before it's added)

| Package | Why | Network / telemetry |
|---|---|---|
| flutter_riverpod, go_router | your stack | none |
| flutter_blue_plus | BLE central | No telemetry as far as I know. **Its licence changed in recent versions, so I'll verify it permits commercial use before adding it.** If it doesn't, the native layer takes over the central role too (see Q1). |
| drift, sqlite3_flutter_libs, path_provider | local DB | none |
| shared_preferences | settings | none |
| share_plus | system share sheet | none (OS sheet) |
| in_app_purchase | StoreKit / Play Billing | talks only to Apple/Google stores (platform, not us) |
| pigeon, build_runner, drift_dev (dev only) | codegen | not shipped |

Explicitly excluded: Firebase (any part of it), Sentry/Crashlytics, any analytics, any ad or attribution SDK. A CI check will fail if `pubspec.lock` gains any of these.

---

## 5. Unlock ("crack") detection: the honest picture

### Android: solid

`ACTION_USER_PRESENT` (keyguard dismissed) is registered at runtime inside the foreground service, plus `SCREEN_OFF` for "relocked". If the user unlocks and relocks within 10 s, nothing happens. Otherwise it's a crack. If the phone has no lock screen at all, `USER_PRESENT` fires on screen-on, which is still a fair signal.

### iOS: the weak point

- `protectedDataDidBecomeAvailable` / `isProtectedDataAvailable` tells us whether the device is unlocked. **It requires a passcode** (we'd show a note if none is set), and **we can only read it when our app is awake.**
- While locked, our app wakes only on BLE events. So:
  - **If an Android phone is in the group**, its host or relay sends `PING` every 15 s. That wakes iPhones, which check the lock state, giving detection within about 15–25 s (plus the grace window).
  - **In an all-iPhone group**, no phone can run a timer, so nothing wakes anyone and a crack is only noticed when the user returns to Lock In or another BLE event happens. **That isn't acceptable as-is, and the spike will measure it.**
- Things I will **not** do: the silent-audio background trick, location background mode, or private Darwin notifications like `com.apple.springboard.lockstate`. All of them break your principles or App Review rules.

### Honest alternatives for iOS (the spike evaluates all three)

**A. Face-down mode (my recommended iOS default).** Lock In stays in the foreground with the idle timer disabled and `proximityMonitoringEnabled = true`. Face down on a table or in a pocket, the proximity sensor turns the screen off, but the app keeps running fully: BLE, timers and instant detection. Picking the phone up (proximity uncovered), or leaving the app (`willResignActive`), starts the 10 s grace, then a crack.
- *Pros:* reliable, instant, works in all-iPhone groups, needs no entitlement.
- *Cons:* the phone isn't technically "locked". It may use more battery than a locked phone (the spike will measure this). If the phone is left face-up, it stays on: we show "Put it face down" and treat face-up for more than 10 s as a crack.

**B. Screen Time APIs (optional, stronger "actually using apps" signal).**
- Needs the **`com.apple.developer.family-controls` entitlement.** Development builds can use it straight away. **App Store or TestFlight distribution requires requesting approval from Apple via their Family Controls entitlement request form**, which can take weeks and isn't guaranteed. It must be requested from your Apple Developer account.
- It uses `AuthorizationCenter.requestAuthorization(for: .individual)` (iOS 16+, the user confirms with Face ID or passcode), a `DeviceActivityMonitor` app extension, and threshold events ("used any app for 1 minute").
- *Limits:* the extension can't do Bluetooth or wake the main app. It writes to an App Group file that the app reads at its next wake. Minute granularity. Usage data stays on device (Apple's opaque tokens), so "Data Not Collected" stays truthful.
- It's a good *backup* signal, not a real-time one.

**C. Locked + background BLE (your original design).** Fine in mixed groups, weak in all-iPhone groups, as described above.

**My suggestion:** on iOS, default to face-down mode. Offer "lock your phone" mode when an Android phone is in the session. Add Screen Time as an opt-in boost once Apple approves the entitlement. The spike will confirm or overturn this.

**Live Activity note:** without a push server (which we won't have), a Live Activity can only be updated when our app is awake. The countdown itself works fine (`Text(timerInterval:)` runs on its own), but other people's cracks show up on the lock screen only after a BLE wake.

---

## 6. Technical spike (build step 1)

**What it is.** A throwaway app in `spike/lockin_spike/` with no styling, using the native peripheral layer and flutter_blue_plus central. Each phone shows a log of frames and events and writes a CSV log to local storage. You export it with the share sheet; nothing is uploaded.

**Test matrix.** Repeat each run for 30 minutes, with all phones locked, on 2 iPhones and 2 Androids:

| # | Host | Joiners | Mode |
|---|---|---|---|
| 1 | Android | iPhone, iPhone, Android | locked |
| 2 | iPhone | iPhone, Android, Android | locked |
| 3 | iPhone | iPhone | locked (all-iOS worst case) |
| 4 | iPhone | iPhone, Android | iOS face-down mode |
| 5 | Android → killed at 10 min | rest | handover |
| 6 | any | one phone walked out of range for 2 min, then back | away/rejoin |

**What we measure.**
- Link uptime %.
- Frame delivery rate and latency.
- Unlock-to-detect latency on each platform.
- False cracks.
- Handover success and time.
- Battery drain per 30 min.
- iOS app termination (with and without state restoration).
- Effects of Android OEM battery killers.

**Pass bar (proposal).**
- ≥ 95 % frame delivery in mixed groups.
- Android unlock detected ≤ 2 s.
- iOS detection ≤ 30 s in mixed groups.
- Zero false cracks.
- Battery drain ≤ 5 % per 30 min.

I'll report the results as they come, including failures, before building step 2.

**What I need from you for the spike:** to run it on your 4 phones. I can't run real BLE hardware from this cloud environment, and Flutter isn't installed here yet either. I'll write the spike so each run is: install, open on all phones, tap Host or Join, lock, wait, then export the logs and send them to me.

---

## 7. Decisions I need from you

1. **BLE stack:** keep flutter_blue_plus for the central role (your spec), or do both roles natively behind one Pigeon interface? I lean native-both. It puts iOS state restoration and Android connection quirks in one place, and it avoids the licence question. The cost is about 2 extra days of work.
2. **Protocol additions** in §2.4: approve?
3. **Handover tiebreak** "prefer Android" in §2.6: approve?
4. **iOS default mode:** face-down mode as the iOS default, pending the spike results?
5. **Screen Time:** do you want me to prepare the Family Controls entitlement request text so you can submit it from your Apple Developer account early, given the wait?
6. **Minimum OS:** I propose iOS 16.1 (for Live Activities and `.individual` Screen Time auth) and Android 8.0 / API 26.

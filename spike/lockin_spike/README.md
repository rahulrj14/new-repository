# Lock In Lab (spike, part 1: detection)

A throwaway test app that answers one question on a real phone: **can we reliably tell when someone uses their phone during a session?** It runs on a single phone. It has no Bluetooth yet and no storage, and release builds have **no internet permission**, so the app cannot send anything anywhere.

## Android (primary)

### Install the test build

1. On the Android phone, download `lock-in-lab.apk` (Claude sends it in the chat).
2. Open it. Android asks to allow installs from that app (your browser, Files or the Claude app). Allow it, then tap **Install**.
   - Play Protect may warn that the app is from an unknown developer. That's expected for a test build. Choose **Install anyway**.
3. Open **Lock In Lab**. When you tap Start the first time, allow notifications. That shows the "Locked in" notification which keeps the session alive while the phone is locked.
4. If the app shows a ⚠️ battery optimisation warning, tap it and set **Lock In Lab → Don't optimise / Unrestricted**. Samsung, Xiaomi, OnePlus and Oppo phones are known to kill background apps otherwise.

To install a newer build later, just install the new APK over the old one.

### Build it yourself (optional)

```sh
cd spike/lockin_spike
flutter build apk --release      # build/app/outputs/flutter-apk/app-release.apk
flutter install                  # with the phone plugged in and USB debugging on
```

### Tests (Android, about 45 minutes in total)

Do each test, tap **Copy log**, and paste the log into the Claude chat. The phone needs a screen lock (PIN, pattern or fingerprint).

| # | Mode | Steps | Expected |
|---|---|---|---|
| A1 | Lock | Tap Start. Within 15 s, press the power button. Wait 2 minutes. Unlock and look at the app. | `deviceLocked` at the time you locked. `deviceUnlocked` at the time you unlocked (no "delivered late" note). 💥 CRACK 10 s after unlocking, because an unlocked phone is a phone in use. |
| A2 | Lock | Start, lock it. After 1 minute, unlock and open **another app** (for example Instagram) for 20 s. Come back. | 💥 CRACK about 10 s after unlocking, **not** "noticed late". This is the key one: detection works even when you're in another app. |
| A3 | Lock | Start, lock it. Unlock, then lock again within 5 s. | "grace started", then "back down after ~5s — no crack". |
| A4 | Lock | Start, lock it. A notification arrives and lights the screen (ask someone to message you). Don't touch the phone. | `screenOnLocked` and **no crack**. |
| A5 | Face-down | Start, put the phone face down within 15 s. Lift it for 5 s, put it back. Then lift and hold it for 15 s. | Screen goes dark face down. The first lift is saved by the grace window, the second cracks. |
| A6 | Lock | Start, lock it, and leave it for **30 minutes**. Then unlock and come back quickly. | `serviceStarted`, no `serviceStopped`, **0 cracks**, and the unlock is detected. Sleep gaps are normal on Android (deep sleep) and harmless. Note the battery drain. |

**A2 and A6 matter most.** A2 shows detection works while in other apps. A6 shows the service survives 30 minutes locked on your phone's brand.

## iPhone (paused)

Building for iPhone needs a Mac with Xcode. The iOS native code is in `ios/Runner/DeviceUseMonitor.swift` but **has not been compiled yet**. To try it on a Mac:

```sh
cd spike/lockin_spike
flutter pub get
open ios/Runner.xcworkspace
```

Then:
1. In Xcode, set your Team under **Signing & Capabilities**.
2. On the iPhone, turn on **Settings → Privacy & Security → Developer Mode**.
3. Run `flutter run --release`.

## Known limitations of this part

- **Incoming calls** take the app out of the foreground. In face-down mode, a call counts as a crack after 10 s. We'll decide later whether calls should be exempt.
- **Swiping Lock In Lab away from Recents** stops the log. The notification may remain until you tap Stop or reopen the app.
- **Nothing is saved.** Copy the log before closing the app.
- **The build is signed with a debug key.** That's fine for testing, but not for the Play Store. Release signing comes with the beta builds step.

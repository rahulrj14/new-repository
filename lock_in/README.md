# Lock In (Android, solo mode)

Put your phone down, earn aura. Unlocking your phone for more than 10 seconds cracks your blob.

The app has no backend, no account, no analytics, and **no internet permission**: nothing can leave the phone.

## What's in this build

- **Onboarding:** pick a blob (8 original characters), get a random nickname from a fixed word list (reroll 🎲), done.
- **Home:** your blob, aura, level, and a session length (25m, 50m, 90m or ∞).
- **Session:**
  - A 10 s settle period, then detection is live.
  - Unlocking starts a 10 s grace window. Lock again in time and nothing happens; otherwise 💥 crack, with haptics.
  - Lock the phone again to keep earning.
  - The notification shows a live countdown on the lock screen.
- **Results:** aura earned, locked minutes, cracks, clean-finish bonus, and level progress.
- **Rules** (in `lib/progression/aura.dart`): 1 aura per locked minute, −5 per crack, +10 for a clean full session of 25 minutes or more, and a daily cap of 300.
- **Settings:** change your blob, haptics, reduce motion, and "keep sessions alive" (opens the app's system settings so battery saver can be set to *No restrictions*).

Not yet in this build: Bluetooth group sessions, streaks and freezes, skins, share cards, iOS.

## Install the test build

Install `lock-in.apk` on the phone, allowing installs from unknown sources when asked. Installing over an older test build keeps your aura.

**On Xiaomi, Samsung or OnePlus:**
1. Open Settings (⚙) and tap **keep sessions alive**.
2. Set **Battery saver → No restrictions**.
3. On Xiaomi, also turn on **Autostart**.

Without this, the phone may kill long sessions. The app will tell you if that happened.

## Test tools

Test builds are built with `--dart-define=LOCKIN_DEBUG_TOOLS=true`. They show 🧪 chips on the session screen:
- **fake lock** and **fake unlock**
- **+1 min** and **+10 min** time skips

These let you see every state on one phone without waiting. Store builds leave the flag off, so this code isn't compiled in at all.

## Build

```sh
flutter test
flutter build apk --release --dart-define=LOCKIN_DEBUG_TOOLS=true   # test build
flutter build apk --release                                          # no test tools
```

## Layout

```
lib/
  catalog/      avatars (painted in code), nickname word lists
  detection/    GraceTracker: pure crack/grace state machine
  session/      SessionEngine (pure time accounting) + Riverpod controller
  progression/  aura rules, levels
  storage/      profile + settings (shared_preferences; moves to drift with streaks)
  platform/     channel to the Android service
  ui/           theme, onboarding, home, session, results
android/…/      LockInService (foreground service + unlock receiver), MainActivity
```

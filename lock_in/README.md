# Lock In (Android, solo mode)

Put your phone down, earn aura. Unlocking your phone for more than 10 seconds cracks your blob.

The app has no backend, no account, no analytics, and **no internet permission**: nothing can leave the phone.

## What's in this build

**Look:** light, bright, chat-app feel. Blue headers, white cards, sticker-style blobs with speech bubbles, and Fredoka type. Hike was the inspiration, but the palette, characters and art are all original.

- **Onboarding:** pick a blob (8 original characters), get a random nickname from a fixed word list (🎲 reroll), done.
- **Tabs:**
  - **Home:** your blob talking to you, level, streak card with this week, session length, and **Lock in**.
  - **Streak:** day count, best streak, freezes, a 4-week calendar, and how it works.
  - **Me:** stats, skins (equip / locked with requirement), change blob, history, settings, and a privacy note.
- **Session:**
  - The screen is blue while you're locked in and turns coral when you unlock. Your blob reacts in a speech bubble.
  - 10 s grace window, then 💥 crack with haptics.
  - Live countdown in the lock-screen notification.
- **Results:** aura, minutes, cracks, clean bonus, streak update (including freezes used or earned), new skins (wear in one tap), level progress, and **share**.
- **Share card:** 1080×1920 story image rendered on the phone, shared through the system share sheet. Nothing is uploaded by the app.
- **Rules:**
  - **Aura:** 1 per locked minute, −5 per crack, +10 for a clean full session of 25 minutes or more, daily cap 300.
  - **Streak:** a day counts once you've locked in 25 minutes. Sessions add up, and there's a 1-minute allowance for the start-up seconds.
  - **Freezes:** earn one every 7 streak days (hold 2). One is used automatically if you miss a day.
  - **Skins:** 9, unlocked by level, streak or sessions. Nothing to buy.
- **Storage:** SQLite (drift) for sessions, daily activity, streak and skins. Profile IDs and settings live in shared preferences. Aura from the first test build is carried over.

Not yet in this build: Bluetooth group sessions, purchases, Live Activity, iOS.

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
dart run build_runner build        # after changing lib/storage/db.dart
flutter test
flutter test test_visual --update-goldens   # renders every screen to test_visual/goldens/ for review
flutter build apk --release --dart-define=LOCKIN_DEBUG_TOOLS=true   # test build
flutter build apk --release                                          # no test tools
```

## Layout

```
lib/
  catalog/      avatars (painted in code), nickname word lists
  detection/    GraceTracker: pure crack/grace state machine
  session/      SessionEngine (pure time accounting) + Riverpod controller
  progression/  aura, levels, streaks + freezes (pure)
  storage/      drift database, ProgressRepo, profile + settings
  platform/     channel to the Android service
  ui/           theme, shell (tabs), home, streak, me, onboarding, session, results, share
android/…/      LockInService (foreground service + unlock receiver), MainActivity
```

# Lock In (Android, solo mode)

Put your phone down, earn aura. Unlocking your phone for more than 10 seconds cracks your blob.

The app has no backend, no account, no analytics, and **no internet permission**: nothing can leave the phone.

## What's in this build

**Look:** light, bright, chat-app feel. Blue headers, white cards, sticker-style blobs with speech bubbles, and Fredoka type. Hike was the inspiration, but the palette, characters and art are all original.

**Solo**
- **Vibes:** study, dinner, gym, sleep or hangout. Each changes the colours and what your blob says.
- **Lengths:** 25, 50 or 90 minutes, or open-ended.
- **Breaks:** optional 25 on, 5 off. Phone use on a break never counts.
- **Unlocking:** starts a 10 s grace window, then 💥 crack.
  - **Clutch save:** relock in the last 3 s for +2 aura and a burst animation.
  - **Emergency pass:** once per session, "I genuinely need my phone" gives 5 minutes with no cracks. It's also a button on the lock-screen notification.

**Progress**
- **Aura and levels.**
- **Daily quest:** one per day, picked from a fixed list, +15 aura. No reminders, ever.
- **Streaks:** 25 locked minutes a day, with freezes.
- **Blob growth:** the blob grows with lifetime locked time (Sprout → Buddy → Glow → Radiant → Legend).
- **Skins:** 14 in total, including seasonal ones (Diwali, Halloween, New Year, exam season) earned by locking in during the season.
- **Stickers:** 8 reaction stickers of your own blob, shared as images through the system share sheet.
- **Lock In Wrapped:** a year-so-far story plus a share card, computed on the phone.

**Squads (Bluetooth, same room)**
- **Joining:** the host shows a QR code. Friends scan it with Lock In's offline scanner (CameraX + ZXing, no ML Kit), and the host taps ✓ to let each one in.
- **Options:** length, vibe, breaks, last one standing 👑, and stakes picked from a fixed list ("first crack buys the snacks 🍟").
- **During a session:** live friend blobs, crack and clutch call-outs, and away detection (60 s out of range = 📡, never "cracked").
- **Squad bonus:** ×1.5 aura if nobody cracks.
- **Afterwards:** squad results with the stake outcome, and a squad share card.
- **Privacy:**
  - Frames are AES-GCM encrypted with a key that only exists in the QR code.
  - The advertised Bluetooth id is derived from that key, so it reveals nothing about who is hosting.
  - There's no pairing, and nothing but catalog IDs and numbers ever crosses the air.

**Storage:** SQLite (drift, schema v2 with migration) for sessions, daily activity, streak and skins. Profile IDs and settings live in shared preferences.

**Not yet:** host handover (if the host leaves, everyone finishes solo), purchases, Live Activity, iOS.

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

These let you see every state on one phone without waiting. In a squad lobby, **🧪 add a fake friend** adds simulated friends that join over an in-memory "radio", speaking the real protocol. During the session, **🧪 friend cracks** and **🧪 friends relock** drive them. Store builds leave the flag off, so this code isn't compiled in at all.

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

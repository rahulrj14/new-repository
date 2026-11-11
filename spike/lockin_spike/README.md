# Lock In Lab (spike, part 1: detection)

A throwaway test app that answers one question on a real iPhone: **can we reliably tell when someone picks up their phone?** It runs on a single phone. It has no Bluetooth yet, no storage, no network access and no dependencies beyond Flutter.

## What you need

- **A Mac** with Xcode 26 or later (free from the Mac App Store). iPhone apps can only be built on a Mac.
- **Flutter** 3.50 or later on that Mac: <https://docs.flutter.dev/get-started/install/macos>.
- **Your iPhone** (iOS 16.1 or later) and its cable.
- **An Apple ID.** A free one is enough for this lab. Apps installed with a free Apple ID stop opening after 7 days; just run again to reinstall.

## One-time setup

1. On the iPhone, open **Settings → Privacy & Security → Developer Mode** and turn it on. The phone restarts.
2. Make sure the iPhone has a **passcode**. Lock detection needs one.
3. On the Mac:
   ```sh
   git clone https://github.com/rahulrj14/new-repository.git
   cd new-repository
   git checkout claude/lock-in-mobile-app-pz6833
   cd spike/lockin_spike
   flutter pub get
   open ios/Runner.xcworkspace
   ```
4. In Xcode:
   1. Select **Runner** in the left sidebar, then **Signing & Capabilities**.
   2. Under **Team**, pick your Apple ID (add it with *Add Account…* if needed).
   3. If Xcode complains about the bundle identifier, change it to something unique, for example `app.lockin.lab.yourname`.

## Run it on the iPhone

Plug in the iPhone, unlock it, then on the Mac:

```sh
flutter run --release
```

Use `--release` because debug builds behave differently when the phone is locked. On first install, iOS may say "Untrusted Developer". If it does, go to **Settings → General → VPN & Device Management**, tap your Apple ID and choose **Trust**.

## What to test (about 15 minutes)

Do each test, then tap **Copy log** and paste the log into the Claude chat.

| # | Mode | Steps | Expected |
|---|---|---|---|
| 1 | Face-down | Tap Start. Within 15 s, put the phone face down on a table. Leave it for 2 minutes. Lift it and look. | Screen went dark while face down. **0 cracks. 0 sleep gaps.** |
| 2 | Face-down | Start, put it face down. After the "armed" message, lift it for about 5 s, then put it back down. | "grace started", then "back down after 5s — no crack". |
| 3 | Face-down | Start, put it face down. Lift it and keep holding it for 15 s. | 💥 CRACK about 10 s after lifting, plus a strong haptic. |
| 4 | Face-down | Start, put it face down. Lift it, go to the Home Screen and open another app for 20 s, then come back. | 💥 CRACK about 10 s after leaving, ideally **not** marked "noticed late". |
| 5 | Face-down | Start, put it face down. Lift it and press the side button to lock it. Wait 1 minute, then unlock and return. | **No crack from locking.** A crack about 10 s after you unlocked, probably "noticed late". |
| 6 | Lock | Start, press the side button within 15 s. Wait 2 minutes, unlock, and return to the app. | Expect a "😴 app was asleep" gap. Note whether "deviceUnlocked" appears and how late it was delivered. |
| 7 | Face-down | Start, put it face down, and leave it for **30 minutes**. | 0 cracks, 0 sleep gaps. **Note the battery drain.** |

**Test 7 is the most important.** It shows whether face-down mode keeps the app alive and what it costs in battery.

## What each result tells us

- **Tests 1–3:** whether face-down mode works at all. The screen turning off over the proximity sensor while the app stays alive is the core trick.
- **Test 4:** whether iOS gives us enough background time to judge the 10 s grace window in real time. If it does, cracks reach friends immediately once Bluetooth is added.
- **Tests 5–6:** how blind iOS is once the phone is properly locked. Expect it to be blind; this is the known limitation.
- **Test 7:** battery drain and reliability over a real session length.

## Known limitations of this part

- **Android:** the native layer isn't written yet, so the app runs but shows no events. Android unlock detection (`ACTION_USER_PRESENT`) is well understood and comes with the Bluetooth part.
- **Incoming calls:** an incoming call takes the app out of the foreground and will count as a crack after 10 s. We'll decide later whether calls should be exempt.
- **Nothing is saved.** If the app is closed, the log is gone, so copy it first.

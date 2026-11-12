# Google Play: listing and release checklist

## App identity (permanent once uploaded)
- **Package name:** `app.lockin.android`
- **First version:** 0.9.0 (versionCode 1). Every upload needs a higher versionCode: bump `version:` in `lock_in/pubspec.yaml`.

## Store listing

**App name (30 max)**
```
Lock In: phones down together
```

**Short description (80 max)**
```
Lock your phones with friends. Unlock and your blob cracks. Earn aura together.
```

**Full description**
```
Phones down, aura up. 🔒

Lock In is the phone-down game for friends in the same room. Start a session, lock your phone, and earn aura while your blob naps. Unlock your phone and your blob CRACKS 💔. In a squad, everyone sees it happen.

🫶 SQUAD UP
• One friend shows a QR code, everyone scans it, the host taps ✓
• Live blobs: see who's locked in and who cracked, in real time
• Last one standing 👑, or keep the whole squad clean for ×1.5 aura
• Fun stakes: "first crack buys the snacks 🍟"
• Works over Bluetooth in the same room. No internet needed.

🔥 KEEP IT GOING
• Streaks with freezes. One off day never wipes you out.
• A daily quest, levels from NPC to Final Boss, and a blob that grows
• 14 skins and 8 stickers, all earned by keeping your phone down. Nothing to buy.
• Lock In Wrapped: your year, made for sharing

☕ BUILT TO BE HEALTHY
• Break mode (25 on, 5 off) and an emergency pass when you genuinely need your phone
• A daily aura cap. No reminders, no guilt trips, no notifications to pull you back.

🔒 PRIVATE BY DESIGN
• No account. No ads. No tracking. No location.
• Lock In has no internet access at all. Your stats never leave your phone.
• Squad messages are encrypted. Only phones that scanned the code can read them.

Study sessions, dinner, gym, hangouts: lock in together.
```

- **Category:** Productivity. Lifestyle also fits; Productivity matches "study" searches.
- **Tags:** focus, study, digital wellbeing, friends.
- **Contact email:** *your email (required, shown publicly)*.
- **Privacy policy URL:** see `docs/privacy/` (published with GitHub Pages; steps in `docs/privacy/README.md`).

## Graphics (in this folder)
| Asset | File |
|---|---|
| App icon 512×512 | `icon-512.png` |
| Feature graphic 1024×500 | `feature-graphic-1024x500.png` |
| Phone screenshots 1080×1920 (upload 4–7) | `screenshots/1-home.png` … `7-streak.png` |

To regenerate after UI changes:
```sh
cd lock_in
flutter test tool/store_assets_test.dart
flutter test tool/store_screenshots_test.dart
```

## Policy forms in Play Console
- **Data safety:** see `DATA_SAFETY.md`. In short: no data collected, no data shared.
- **Content rating (IARC):**
  - **Violence:** no.
  - **User-generated content / communication between users:** no. Players exchange only preset avatar and nickname IDs, with no chat, text, photos or links.
  - **Location sharing:** no.
  - **Digital purchases:** no.
  - **Gambling:** no. Stakes are a fixed list of jokes with no money involved.
- **Target audience:** 13–15, 16–17 and 18+. Answer "Yes" to "appeals to children" only if you plan to market to under-13s (we don't).
  - **For the teen groups:** no ads, no data collection, and no contact between strangers (joining needs an in-person QR scan plus host approval).
- **Ads:** "No, my app does not contain ads".
- **Foreground service declaration:**
  - **Type:** "Special use".
  - **Description:** "Keeps a focus session the user explicitly started running while the phone is locked, so the app can notice an unlock. Stops when the session ends."
  - **Video:** Play may ask for a short screen recording. Record one session start → lock → unlock → crack.
- **Permissions:**
  - **Camera:** used only to scan a friend's join code.
  - **Location:** declared only for Android 11 and older, and only because those versions require it for Bluetooth scanning. The app never reads location.

## Release steps
1. **Create the developer account:** Play Console → Create developer account (US$25 one-time).
   - **Note:** new personal accounts must run a **closed test with ≥12 testers for 14 continuous days** before production access.
2. **Create the app:** name as above, default language English (UK or India), free.
3. **Store listing:** fill it in from this file and upload the graphics.
4. **Policy forms:** App content → complete the forms above.
5. **Internal testing:** Release → Testing → Internal testing → upload `app-release.aab` and add yourself. This takes minutes and proves the upload works.
6. **Closed testing:** create a track, add ≥12 testers by email or Google Group, and send them the opt-in link. Keep it running for 14+ days.
7. **Apply for production access:** answer the questions about your test. Your notes from squad sessions help here.

## Signing
- **Play App Signing:** accept it when asked. Google holds the app-signing key.
- **Upload key:** the AAB is signed with your upload key (`lockin-upload.jks`). Keep that file and its password safe and private.
- **Lost or leaked upload key:** Play Console → Setup → App signing → "Request upload key reset". Your app and users are unaffected.
- **Building on another machine:** create `lock_in/android/key.properties`. It's gitignored, so never commit it.
  ```
  storeFile=/full/path/to/lockin-upload.jks
  storePassword=…
  keyAlias=upload
  keyPassword=…
  ```
  Then run `flutter build appbundle --release`.

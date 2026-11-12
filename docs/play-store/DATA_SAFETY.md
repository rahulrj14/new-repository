# Google Play Data safety answers

How to answer the Data safety form, and why each answer is true.

## Overview questions
| Question | Answer | Why |
|---|---|---|
| Does your app collect or share any of the required user data types? | **No** | The release build has **no INTERNET permission**, so it physically cannot send anything to us or to third parties. |
| Is all user data encrypted in transit? | *Not asked* when no data is collected. | Squad frames between nearby phones are AES-GCM encrypted anyway. |
| Do you provide a way to request data deletion? | *Not asked*. | Uninstalling deletes everything, and nothing is stored anywhere else. |

The form then shows: **"No data collected"** and **"No data shared with third parties"**.

## Edge cases we checked
- **Bluetooth between friends.** Play's definition of "collected" is data transmitted **off the device to the developer or a third party**. Squad frames go phone-to-phone in the same room. They never reach us, and they contain only preset IDs and numbers (avatar, nickname, skin, status, counters).
- **Share cards and stickers.** These are images the user chooses to send through Android's share sheet. User-initiated sharing to an app the user picks isn't collection.
- **Camera.** It's used only to scan a join QR code. Frames are analysed in memory and never stored or sent.
- **Location permission.** It's declared only for Android 11 and older (`maxSdkVersion=30`), because those versions require it for Bluetooth scanning. On those versions the app asks for the permission only when you start or join a squad, and never reads, stores or sends a location. On Android 12+, scanning is declared `neverForLocation`.
- **Crash and ANR reports in Play Console.** Android collects these itself, under the user's own device settings. The app includes no crash-reporting SDK.
- **Feedback form (optional).** If you add one, the in-app link only opens a web page in the browser. Whatever people type there goes to that form provider, not through the app. Mention it in the privacy policy.
- **Android backup.** Cloud backup is **off** (`allowBackup=false`, and `data_extraction_rules.xml` excludes everything from cloud backup), so nothing goes to Google Drive. Direct phone-to-phone transfer (cable or setup wizard, Android 12+) is allowed, so streaks can move to a new phone without touching the cloud.

## Re-check before every release
```sh
aapt2 dump permissions app-release.apk   # must NOT list android.permission.INTERNET
```
Adding any SDK that needs internet (analytics, ads, crash reporting) would make these answers false. Don't, without updating this file and the privacy policy.
